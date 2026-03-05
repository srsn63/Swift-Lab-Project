import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct CellListView: View {
    let blockId: String
    let blockName: String

    @State private var cells: [Cell] = []
    @State private var error: String?

    var body: some View {
        List {
            if let error { Text(error).foregroundStyle(.red) }

            ForEach(cells) { c in
                HStack {
                    Text(c.cellCode)
                    Spacer()
                    Text("\(c.occupancy)/\(c.capacity)")
                        .foregroundStyle(c.occupancy >= c.capacity ? .red : .secondary)
                }
            }
        }
        .navigationTitle("\(blockName) Cells")
        .task {
            FirebaseManager.shared.cellsRef(blockId: blockId)
                .addSnapshotListener { snap, err in
                    if let err { self.error = err.localizedDescription; return }
                    self.cells = snap?.documents.compactMap { try? $0.data(as: Cell.self) } ?? []
                    self.cells.sort { $0.cellCode < $1.cellCode }
                }
        }
    }
}
