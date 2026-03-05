import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Block: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var createdAt: Timestamp
    var createdBy: String
}
