import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class AdminUserManagementViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var blocks: [Block] = []
    @Published var errorMessage: String?

    @Published var searchText: String = ""
    @Published var selectedRole: String = "all"
    @Published var selectedStatus: String = "all"

    private var listener: ListenerRegistration?

    deinit { listener?.remove() }

    var filteredUsers: [User] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return users.filter { user in
            let name = (user.fullName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let badge = (user.badgeNumber ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

            let matchesRole = selectedRole == "all" || user.role == selectedRole
            let matchesStatus = selectedStatus == "all" || user.status == selectedStatus
            let matchesSearch = query.isEmpty
                || user.email.lowercased().contains(query)
                || name.lowercased().contains(query)
                || badge.lowercased().contains(query)

            return matchesRole && matchesStatus && matchesSearch
        }
    }

    var pendingCount: Int {
        users.filter { $0.status == "pending" }.count
    }

    var approvedCount: Int {
        users.filter { $0.status == "approved" }.count
    }

    func startListener() {
        listener?.remove()
        errorMessage = nil

        listener = FirebaseManager.shared.usersRef
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }

                if let err {
                    self.users = []
                    self.errorMessage = err.localizedDescription
                    return
                }

                let list = snap?.documents.compactMap { try? $0.data(as: User.self) } ?? []
                self.users = list.sorted { $0.email < $1.email }
            }
    }

    func stopListener() {
        listener?.remove()
        listener = nil
    }

    func loadBlocks() async {
        do {
            let snap = try await FirebaseManager.shared.blocksRef.getDocuments()
            var list = snap.documents.compactMap { try? $0.data(as: Block.self) }
            list = list.filter { $0.id != nil }.sorted { $0.name < $1.name }
            blocks = list
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func blockName(for blockId: String?) -> String {
        guard let blockId, !blockId.isEmpty else { return "Unassigned" }
        return blocks.first(where: { $0.id == blockId })?.name ?? blockId
    }

    func displayName(for user: User) -> String {
        let trimmed = (user.fullName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? user.email : trimmed
    }

    func showEmailSubtitle(for user: User) -> Bool {
        let trimmed = (user.fullName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty
    }

    func setApproval(uid: String, approved: Bool, status: String) async throws {
        try await FirebaseManager.shared.usersRef.document(uid).updateData([
            "approved": approved,
            "status": status
        ])
    }

    func updateUser(
        uid: String,
        role: String,
        fullName: String,
        badgeNumber: String,
        assignedBlockId: String,
        approved: Bool,
        status: String
    ) async throws {
        var payload: [String: Any] = [
            "role": role,
            "fullName": fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            "badgeNumber": badgeNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            "approved": approved,
            "status": status
        ]

        if role == "guard" {
            payload["assignedBlockId"] = assignedBlockId
        } else {
            payload["assignedBlockId"] = ""
        }

        try await FirebaseManager.shared.usersRef.document(uid).updateData(payload)
    }

    func deleteUser(uid: String) async throws {
        try await FirebaseManager.shared.usersRef.document(uid).delete()
    }
}
