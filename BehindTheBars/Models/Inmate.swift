import Foundation
import FirebaseFirestoreSwift

struct Inmate: Identifiable, Codable {
    @DocumentID var id: String?

    var firstName: String
    var lastName: String
    var securityLevel: String

    var blockId: String
    var cellId: String

    var admissionDate: Date
    var sentenceMonths: Int
    var releaseDate: Date

    var isSolitary: Bool
    var isDeleted: Bool? = nil

    var fullName: String { "\(firstName) \(lastName)" }
}
