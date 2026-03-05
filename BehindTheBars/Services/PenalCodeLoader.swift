import Foundation

enum PenalCodeLoader {
    static func load() -> [PenalCode] {
        guard let url = Bundle.main.url(forResource: "penal_codes", withExtension: "json") else {
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([PenalCode].self, from: data)
        } catch {
            return []
        }
    }
}
