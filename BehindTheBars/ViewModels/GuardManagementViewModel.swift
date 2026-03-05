import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class GuardManagementViewModel: ObservableObject {
    @Published var guards: [User] = []
    @Published var errorMessage: String?

    private let ref = FirebaseManager.shared.usersRef
    private var listener: ListenerRegistration?

    deinit { listener?.remove() }

    func startListener() {
        listener?.remove()

        // No orderBy -> no composite index required
        listener = ref.whereField("role", isEqualTo: "guard")
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let err {
                    self.errorMessage = err.localizedDescription
                    return
                }

                let list = snap?.documents.compactMap { try? $0.data(as: User.self) } ?? []
                // client-side sort by createdAt desc
                self.guards = list.sorted { $0.createdAt.dateValue() > $1.createdAt.dateValue() }
            }
    }

    func updateGuard(uid: String, fullName: String, badgeNumber: String, assignedBlock: String) async throws {
        let data: [String: Any] = [
            "fullName": fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            "badgeNumber": badgeNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            "assignedBlock": assignedBlock.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        try await ref.document(uid).updateData(data)
    }

    func deleteGuardDoc(uid: String) async throws {
        try await ref.document(uid).delete()
    }
}
