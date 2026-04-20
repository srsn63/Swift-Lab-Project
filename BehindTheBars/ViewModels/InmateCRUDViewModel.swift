import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class InmateCRUDViewModel: ObservableObject {

    @Published var inmates: [Inmate] = []
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?

    deinit { listener?.remove() }

    // MARK: LISTENER

    func startListener() {
        startListener(blockIdFilter: nil)
    }

    func startListener(blockIdFilter: String?) {
        listener?.remove()
        errorMessage = nil

        var query: Query = FirebaseManager.shared.inmatesRef

        if let specificBlockId = BlockAssignment.specificBlockId(blockIdFilter) {
            query = query.whereField("blockId", isEqualTo: specificBlockId)
        }

        listener = query.addSnapshotListener { [weak self] snap, err in
            guard let self else { return }

            if let err {
                self.inmates = []
                self.errorMessage = err.localizedDescription
                return
            }

            let list = snap?.documents.compactMap { try? $0.data(as: Inmate.self) } ?? []
            self.inmates = list
                .filter { $0.isDeleted != true }
                .sorted { $0.fullName < $1.fullName }
        }
    }

    func stopListener() {
        listener?.remove()
        listener = nil
    }

    // MARK: UPDATE

    func update(inmateId: String, inmate: Inmate) async throws {
        try FirebaseManager.shared.inmatesRef
            .document(inmateId)
            .setData(from: inmate, merge: true)
    }

    // MARK: DELETE INMATE + DECREMENT CELL OCCUPANCY

    func delete(inmateId: String) async throws {

        let db = Firestore.firestore()
        let inmateRef = FirebaseManager.shared.inmatesRef.document(inmateId)

        try await db.runTransaction { transaction, errorPointer in

            do {

                let inmateSnap = try transaction.getDocument(inmateRef)
                let inmate = try inmateSnap.data(as: Inmate.self)

                let cellRef = FirebaseManager.shared
                    .cellsRef(blockId: inmate.blockId)
                    .document(inmate.cellId)

                let cellSnap = try transaction.getDocument(cellRef)
                let cell = try cellSnap.data(as: Cell.self)

                let newOcc = max(0, cell.occupancy - 1)

                transaction.updateData(
                    ["occupancy": newOcc],
                    forDocument: cellRef
                )

                transaction.deleteDocument(inmateRef)

            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            return nil
        }
    }

    // MARK: CREATE INMATE + INCREMENT CELL OCCUPANCY

    func createInmateWithCellIncrement(
        inmate: Inmate,
        blockId: String,
        cellId: String
    ) async throws {

        let db = Firestore.firestore()

        let inmateRef =
            FirebaseManager.shared.inmatesRef.document()

        let cellRef =
            FirebaseManager.shared
                .cellsRef(blockId: blockId)
                .document(cellId)

        try await db.runTransaction { transaction, errorPointer in

            do {

                let cellSnap = try transaction.getDocument(cellRef)
                let cell = try cellSnap.data(as: Cell.self)

                if cell.occupancy >= cell.capacity {
                    let err = NSError(
                        domain: "CellFull",
                        code: 1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Cell is full."
                        ]
                    )
                    errorPointer?.pointee = err
                    return nil
                }

                transaction.updateData(
                    ["occupancy": cell.occupancy + 1],
                    forDocument: cellRef
                )

                try transaction.setData(
                    from: inmate,
                    forDocument: inmateRef,
                    merge: false
                )

            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            return nil
        }
    }
}
