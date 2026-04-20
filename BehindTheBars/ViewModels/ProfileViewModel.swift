import Foundation
import FirebaseFirestore

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var fullName: String = ""
    @Published var badgeNumber: String = ""
    @Published var assignedBlockId: String = ""   // guards only
    @Published var errorMessage: String?

    func load(from user: User) {
        fullName = user.fullName ?? ""
        badgeNumber = user.badgeNumber ?? ""
        assignedBlockId = user.assignedBlockId ?? ""
    }

    // Users can edit only personal details.
    // Guards should NOT be allowed to self-change assignedBlockId by rules, but keeping field here
    // lets you display it; you can disable editing in the view for guards.
    func save(uid: String, includeAssignedBlockId: Bool) async throws {
        var data: [String: Any] = [
            "fullName": fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            "badgeNumber": badgeNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        ]

        if includeAssignedBlockId {
            data["assignedBlockId"] = BlockAssignment.normalized(assignedBlockId)
        }

        try await FirebaseManager.shared.usersRef
            .document(uid)
            .updateData(data)
    }
}
