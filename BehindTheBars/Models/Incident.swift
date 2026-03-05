import Foundation
import FirebaseFirestoreSwift

struct Incident: Identifiable, Codable {
    @DocumentID var id: String?

    var reportedBy: String
    var blockId: String
    var involvedInmates: [String]
    var description: String
    var timestamp: Date
    var severity: Int
    var penalCode: String
}
