import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class DashboardStatsViewModel: ObservableObject {
    @Published var totalInmates: Int = 0
    @Published var staffCount: Int = 0
    @Published var activeIncidents: Int = 0
    @Published var guardsOnDuty: Int = 0
    @Published var autoReleaseAlerts: Int = 0
    @Published var inmatesPerBlock: [(name: String, count: Int)] = []
    @Published var incidentByDay: [(day: String, count: Int)] = []
    @Published var errorMessage: String?

    func load() async {
        errorMessage = nil

        do {
            async let inmatesTask = FirebaseManager.shared.inmatesRef.getDocuments()
            async let blocksTask = FirebaseManager.shared.blocksRef.getDocuments()
            async let staffTask = FirebaseManager.shared.staffRef.getDocuments()
            async let incidentsTask = FirebaseManager.shared.incidentsRef.getDocuments()
            async let usersTask = FirebaseManager.shared.usersRef.whereField("role", isEqualTo: "guard").getDocuments()

            let (inmatesSnap, blocksSnap, staffSnap, incidentsSnap, guardsSnap) = try await (
                inmatesTask, blocksTask, staffTask, incidentsTask, usersTask
            )

            let blocks = blocksSnap.documents.compactMap { try? $0.data(as: Block.self) }
            var blockMap: [String: String] = [:]
            for block in blocks {
                guard let id = block.id else { continue }
                blockMap[id] = block.name
            }

            let inmates = inmatesSnap.documents.compactMap { try? $0.data(as: Inmate.self) }
                .filter { $0.isDeleted != true }

            totalInmates = inmates.count
            autoReleaseAlerts = inmates.filter { $0.releaseDate <= Date() }.count

            var blockCounts: [String: Int] = [:]
            for inmate in inmates {
                let name = blockMap[inmate.blockId] ?? inmate.blockId
                blockCounts[name, default: 0] += 1
            }
            inmatesPerBlock = blockCounts
                .map { (name: $0.key, count: $0.value) }
                .sorted { $0.name < $1.name }

            let staff = staffSnap.documents.compactMap { try? $0.data(as: Staff.self) }
                .filter { $0.isDeleted != true }
            staffCount = staff.count

            let incidents = incidentsSnap.documents.compactMap { try? $0.data(as: Incident.self) }
            let activeStatuses = Set(["REPORTED", "UNDER_REVIEW", "INVESTIGATING"])
            activeIncidents = incidents.filter { activeStatuses.contains($0.lifecycleStatus) }.count
            incidentByDay = buildIncidentsByDay(incidents)

            let now = Date()
            let currentShift = inferCurrentShift()
            guardsOnDuty = guardsSnap.documents.filter { doc in
                let data = doc.data()
                let isDeleted = data["isDeleted"] as? Bool ?? false
                guard !isDeleted else { return false }

                if let dutyStartAt = data["dutyStartAt"] as? Timestamp {
                    return ShiftDutySchedule.status(for: dutyStartAt.dateValue(), now: now).isOnDuty
                }

                let rawShift = data["shift"] as? String
                return normalizedShift(rawShift, fallback: currentShift) == currentShift
            }.count

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func inferCurrentShift() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<14: return "morning"
        case 14..<22: return "day"
        default: return "night"
        }
    }

    private func normalizedShift(_ shift: String?, fallback: String) -> String {
        let value = (shift ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch value {
        case "morning", "day", "night":
            return value
        default:
            return fallback
        }
    }

    private func buildIncidentsByDay(_ incidents: [Incident]) -> [(day: String, count: Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        var output: [(day: String, count: Int)] = []
        for offset in stride(from: 6, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let start = calendar.startOfDay(for: date)
            guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { continue }
            let count = incidents.filter { $0.timestamp >= start && $0.timestamp < end }.count
            output.append((day: formatter.string(from: date), count: count))
        }
        return output
    }
}
