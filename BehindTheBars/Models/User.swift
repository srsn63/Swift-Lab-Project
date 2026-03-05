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
}		
