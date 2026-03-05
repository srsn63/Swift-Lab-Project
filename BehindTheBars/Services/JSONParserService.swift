import Foundation

class JSONParserService {
    
    static func loadPenalCodes() -> [PenalCode] {
        
        guard let url = Bundle.main.url(forResource: "penal_codes", withExtension: "json") else {
            print("JSON file not found.")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([PenalCode].self, from: data)
            return decoded
        } catch {
            print("Error decoding JSON:", error.localizedDescription)
            return []
        }
    }
}
