import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Cell: Identifiable, Codable {
    @DocumentID var id: String?   // e.g. "A101"
    var cellCode: String          // "A101"
    var blockName: String         // "A"
    var capacity: Int             // 2
    var occupancy: Int            // 0..2
}
