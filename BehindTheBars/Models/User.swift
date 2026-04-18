import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct User: Identifiable, Codable {
    @DocumentID var id: String?

    let uid: String
    let email: String
    let role: String
    let createdAt: Timestamp

    var approved: Bool
    var status: String // pending/approved/denied

    var fullName: String?
    var badgeNumber: String?
    var assignedBlockId: String?
    var shift: String?
    var dutyStartAt: Timestamp?
    var isDeleted: Bool? = nil

    var dutyAnchorDate: Date? {
        dutyStartAt?.dateValue()
    }

    var resolvedShift: String {
        ShiftDutySchedule.normalizedShiftName(shift, anchorDate: dutyAnchorDate, fallback: "day")
    }
}
