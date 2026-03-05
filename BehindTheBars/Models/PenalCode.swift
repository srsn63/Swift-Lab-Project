import Foundation

struct PenalCode: Identifiable, Codable {
    var id: String { code }
    let code: String
    let title: String
    let description: String
    let severityLevel: Int
}
