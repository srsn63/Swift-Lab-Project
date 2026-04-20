import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class InmateSelectionViewModel: ObservableObject {
    @Published var inmates: [Inmate] = []
    @Published var searchText: String = ""
    @Published var errorMessage: String?

    private let filterBlockId: String?
    private var listener: ListenerRegistration?

    init(filterBlockId: String?) {
        self.filterBlockId = filterBlockId
        start()
    }

    deinit { listener?.remove() }

    var filteredInmates: [Inmate] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return inmates }
        return inmates.filter { $0.fullName.lowercased().contains(q) || $0.cellId.lowercased().contains(q) }
    }

    private func start() {
        listener?.remove()

        var query: Query = FirebaseManager.shared.inmatesRef
        if let specificBlockId = BlockAssignment.specificBlockId(filterBlockId) {
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
            self.errorMessage = nil
        }
    }
}
