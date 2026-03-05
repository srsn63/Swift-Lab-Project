import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class IncidentReportViewModel: ObservableObject {
    @Published var isSubmitting = false
    @Published var submissionSuccess = false
    @Published var errorMessage: String?

    // Pass currentUser + selectedInmates so we can determine blockId correctly
    func submitIncident(
        currentUser: User,
        description: String,
        severity: Int,
        selectedInmates: [Inmate],
        penalCode: String
    ) async {
        let desc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let code = penalCode.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !desc.isEmpty else {
            errorMessage = "Description is required."
            return
        }
        guard (1...5).contains(severity) else {
            errorMessage = "Severity must be 1 to 5."
            return
        }
        guard !selectedInmates.isEmpty else {
            errorMessage = "Please select at least one inmate."
            return
        }
        guard !code.isEmpty else {
            errorMessage = "Penal code is required."
            return
        }

        // Determine incident blockId
        let blockId: String
        if currentUser.role == "guard" {
            guard let assigned = currentUser.assignedBlockId, !assigned.isEmpty else {
                errorMessage = "Guard is not assigned to a block."
                return
            }
            // Guards can only report for their own block; enforce client-side too
            let invalid = selectedInmates.contains { $0.blockId != assigned }
            if invalid {
                errorMessage = "You can only report incidents for inmates in your assigned block."
                return
            }
            blockId = assigned
        } else {
            // Warden/admin: derive from the first selected inmate
            // (If you later support cross-block incidents, you must redesign schema/rules.)
            blockId = selectedInmates[0].blockId
            let mixed = selectedInmates.contains { $0.blockId != blockId }
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
            blockId: blockId,
            involvedInmates: inmateIds,
            description: desc,
            timestamp: Date(),
            severity: severity,
            penalCode: code
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
