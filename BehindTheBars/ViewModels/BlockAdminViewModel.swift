import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class BlockAdminViewModel: ObservableObject {
    @Published var blocks: [Block] = []
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?

    func startListener() {
        listener?.remove()
        listener = FirebaseManager.shared.blocksRef
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let err { self.errorMessage = err.localizedDescription; return }
                self.blocks = snap?.documents.compactMap { try? $0.data(as: Block.self) } ?? []
            }
    }

    func createBlock(name: String, createdBy: String) async throws {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !name.isEmpty else { return }

        let block = Block(id: nil, name: name, createdAt: Timestamp(date: Date()), createdBy: createdBy)
        let blockRef = FirebaseManager.shared.blocksRef.document() // auto-id
        let cellsRef = blockRef.collection("cells")

        let batch = FirebaseManager.shared.firestore.batch()
        batch.setData(try Firestore.Encoder().encode(block), forDocument: blockRef)

        // Generate 20 cells: A101...A120
        for i in 101...120 {
            let cellCode = "\(name)\(i)"
            let cellDoc = cellsRef.document(cellCode)
            let cell = Cell(id: cellCode, cellCode: cellCode, blockName: name, capacity: 2, occupancy: 0)
            batch.setData(try Firestore.Encoder().encode(cell), forDocument: cellDoc)
        }

        try await batch.commit()
    }
}
