import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class IncidentReportViewModel: ObservableObject {
    @Published var isSubmitting = false
    @Published var submissionSuccess = false
    @Published var errorMessage: String?

    func submitIncident(
        currentUser: User,
        description: String,
        severity: Int,
        selectedInmates: [Inmate],
        penalCode: String
    ) async {
        let desc = description.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !desc.isEmpty else { errorMessage = "Description required."; return }
        guard (1...5).contains(severity) else { errorMessage = "Severity must be 1..5."; return }
        guard !selectedInmates.isEmpty else { errorMessage = "Select inmates."; return }
        guard !penalCode.isEmpty else { errorMessage = "Select penal code."; return }

        // Determine incident block and enforce guard restrictions
        let incidentBlockId: String

        if currentUser.role == "guard" {
            guard let assigned = currentUser.assignedBlockId, !assigned.isEmpty else {
                errorMessage = "You are not assigned to a block."
                return
            }
            let invalid = selectedInmates.contains { $0.blockId != assigned }
            if invalid {
                errorMessage = "Guards can only use inmates from their assigned block."
                return
            }
            incidentBlockId = assigned
        } else {
            // warden/admin: force single-block incident for now
            incidentBlockId = selectedInmates[0].blockId
            let mixed = selectedInmates.contains { $0.blockId != incidentBlockId }
            if mixed {
                errorMessage = "All selected inmates must be from the same block."
                return
            }
        }

        isSubmitting = true
        submissionSuccess = false
        errorMessage = nil

        let inmateIds = selectedInmates.compactMap { $0.id }

        let incident = Incident(
            id: nil,
            reportedBy: currentUser.uid,
            blockId: incidentBlockId,
            involvedInmates: inmateIds,
            description: desc,
            timestamp: Date(),
            severity: severity,
            penalCode: penalCode
        )

        do {
            _ = try FirebaseManager.shared.incidentsRef.addDocument(from: incident)
            submissionSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }
}
