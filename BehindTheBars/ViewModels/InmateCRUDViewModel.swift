import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class InmateCRUDViewModel: ObservableObject {
    @Published var inmates: [Inmate] = []
    @Published var errorMessage: String?

    private let inmatesRef = FirebaseManager.shared.inmatesRef
    private var listener: ListenerRegistration?

    deinit { listener?.remove() }

    func startListener() {
        listener?.remove()
        listener = inmatesRef.addSnapshotListener { [weak self] snap, err in
            guard let self else { return }
            if let err { self.errorMessage = err.localizedDescription; return }
            self.inmates = snap?.documents.compactMap { try? $0.data(as: Inmate.self) } ?? []
            self.inmates.sort { $0.admissionDate > $1.admissionDate }
        }
    }

    func update(inmateId: String, inmate: Inmate) async throws {
        try inmatesRef.document(inmateId).setData(from: inmate, merge: true)
    }

    func createInmateWithCellIncrement(inmate: Inmate, blockId: String, cellId: String) async throws {
        let db = FirebaseManager.shared.firestore
        let cellRef = FirebaseManager.shared.cellsRef(blockId: blockId).document(cellId)
        let inmateRef = inmatesRef.document()

        try await db.runTransaction { transaction, errorPointer in
            do {
                let cellSnap = try transaction.getDocument(cellRef)
                guard var cell = try? cellSnap.data(as: Cell.self) else {
                    throw NSError(domain: "cell", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cell not found"])
                }

                if cell.occupancy >= cell.capacity {
                    throw NSError(domain: "cell", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cell is full"])
                }

                cell.occupancy += 1
                let cellData = try Firestore.Encoder().encode(cell)
                transaction.setData(cellData, forDocument: cellRef, merge: true)

                let inmateData = try Firestore.Encoder().encode(inmate)
                transaction.setData(inmateData, forDocument: inmateRef, merge: false)

                return nil
            } catch let e as NSError {
                errorPointer?.pointee = e
                return nil
            } catch {
                let e = NSError(domain: "txn", code: 999, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
                errorPointer?.pointee = e
                return nil
            }
        }
    }

    func deleteInmateAndDecrementCell(inmateId: String, blockId: String, cellId: String) async throws {
        let db = FirebaseManager.shared.firestore
        let cellRef = FirebaseManager.shared.cellsRef(blockId: blockId).document(cellId)
        let inmateRef = inmatesRef.document(inmateId)

        try await db.runTransaction { transaction, errorPointer in
            do {
                let inmateSnap = try transaction.getDocument(inmateRef)
                guard inmateSnap.exists else {
                    throw NSError(domain: "inmate", code: 1, userInfo: [NSLocalizedDescriptionKey: "Inmate not found"])
                }

                let cellSnap = try transaction.getDocument(cellRef)
                guard var cell = try? cellSnap.data(as: Cell.self) else {
                    throw NSError(domain: "cell", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cell not found"])
                }

                if cell.occupancy > 0 { cell.occupancy -= 1 }
                let cellData = try Firestore.Encoder().encode(cell)
                transaction.setData(cellData, forDocument: cellRef, merge: true)

                transaction.deleteDocument(inmateRef)
                return nil
            } catch let e as NSError {
                errorPointer?.pointee = e
                return nil
            } catch {
                let e = NSError(domain: "txn", code: 999, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
                errorPointer?.pointee = e
                return nil
            }
        }
    }
}
