import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class IncidentListViewModel: ObservableObject {
    @Published var incidents: [Incident] = []
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?

    deinit { listener?.remove() }

    func start() {
        listener?.remove()
        listener = FirebaseManager.shared.incidentsRef.addSnapshotListener { [weak self] snap, err in
            guard let self else { return }
            if let err {
                self.errorMessage = err.localizedDescription
                return
            }
            let list = snap?.documents.compactMap { try? $0.data(as: Incident.self) } ?? []
            self.incidents = list.sorted { $0.timestamp > $1.timestamp }
            self.errorMessage = nil
        }
    }
}
