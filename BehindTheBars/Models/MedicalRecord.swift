import Foundation
import FirebaseFirestoreSwift
import SwiftUI

struct MedicalRecord: Identifiable, Codable {
    @DocumentID var id: String?

    var inmateId: String
    var inmateName: String
    var blockId: String
    var doctorId: String
    var doctorName: String
    var conditionSummary: String
    var treatmentNotes: String
    var status: String
    var createdByUserId: String
    var createdByName: String
    var createdAt: Date
    var updatedAt: Date
    var statusUpdatedAt: Date

    var medicalStatus: MedicalStatus {
        MedicalStatus(rawValue: status) ?? .inTreatment
    }
}

enum MedicalStatus: String, CaseIterable, Identifiable, Codable {
    case inTreatment = "in_treatment"
    case underObservation = "under_observation"
    case referred = "referred"
    case recovered = "recovered"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .inTreatment:
            return "In Treatment"
        case .underObservation:
            return "Observation"
        case .referred:
            return "Referred"
        case .recovered:
            return "Recovered"
        }
    }

    var icon: String {
        switch self {
        case .inTreatment:
            return "cross.case.fill"
        case .underObservation:
            return "eye.fill"
        case .referred:
            return "arrow.triangle.branch"
        case .recovered:
            return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .inTreatment:
            return .orange
        case .underObservation:
            return .blue
        case .referred:
            return .purple
        case .recovered:
            return AppTheme.success
        }
    }
}