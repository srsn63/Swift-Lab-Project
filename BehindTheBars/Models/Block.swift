import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Block: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var createdAt: Timestamp
    var createdBy: String
}

enum BlockAssignment {
    static let allBlocksId = "all"

    static func normalized(_ assignedBlockId: String?) -> String {
        let trimmed = (assignedBlockId ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else { return "" }
        return trimmed.lowercased() == allBlocksId ? allBlocksId : trimmed
    }

    static func isUnassigned(_ assignedBlockId: String?) -> Bool {
        normalized(assignedBlockId).isEmpty
    }

    static func isAllBlocks(_ assignedBlockId: String?) -> Bool {
        normalized(assignedBlockId) == allBlocksId
    }

    static func specificBlockId(_ assignedBlockId: String?) -> String? {
        let value = normalized(assignedBlockId)
        guard !value.isEmpty, value != allBlocksId else { return nil }
        return value
    }

    static func allowsAccess(assignedBlockId: String?, to blockId: String) -> Bool {
        let value = normalized(assignedBlockId)
        guard !value.isEmpty else { return false }
        return value == allBlocksId || value == blockId
    }

    static func displayName(for assignedBlockId: String?, blocks: [Block] = []) -> String {
        let value = normalized(assignedBlockId)

        if value.isEmpty {
            return "Unassigned"
        }

        if value == allBlocksId {
            return "All Blocks"
        }

        return blocks.first(where: { $0.id == value })?.name ?? value
    }
}
