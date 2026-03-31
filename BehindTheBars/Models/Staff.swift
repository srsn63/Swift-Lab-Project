import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI

struct Staff: Identifiable, Codable {
    @DocumentID var id: String?

    var fullName: String
    var staffType: String
    var phoneNumber: String
    var assignedBlockId: String
    var shift: String
    var hireDate: Date
    var isActive: Bool
    var notes: String
    var createdBy: String
    var createdAt: Date
    var updatedAt: Date
}

enum StaffType: String, CaseIterable, Identifiable {
    case doctor
    case nurse
    case medical_assistant
    case kitchen
    case maintenance
    case cleaner
    case clerk
    case counselor
    case visitation_officer
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .doctor: return "Doctor"
        case .nurse: return "Nurse"
        case .medical_assistant: return "Medical Assistant"
        case .kitchen: return "Kitchen"
        case .maintenance: return "Maintenance"
        case .cleaner: return "Cleaner"
        case .clerk: return "Clerk"
        case .counselor: return "Counselor"
        case .visitation_officer: return "Visitation Officer"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .doctor: return "stethoscope"
        case .nurse: return "cross.case.fill"
        case .medical_assistant: return "heart.text.square.fill"
        case .kitchen: return "fork.knife"
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .cleaner: return "sparkles"
        case .clerk: return "doc.text.fill"
        case .counselor: return "bubble.left.and.bubble.right.fill"
        case .visitation_officer: return "person.2.fill"
        case .other: return "person.fill.questionmark"
        }
    }

    var color: Color {
        switch self {
        case .doctor: return .blue
        case .nurse: return .pink
        case .medical_assistant: return .cyan
        case .kitchen: return .orange
        case .maintenance: return .brown
        case .cleaner: return .mint
        case .clerk: return .indigo
        case .counselor: return .purple
        case .visitation_officer: return .teal
        case .other: return .gray
        }
    }
}

enum ShiftType: String, CaseIterable, Identifiable {
    case morning
    case day
    case night

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .day: return "Day"
        case .night: return "Night"
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .day: return "sun.max.fill"
        case .night: return "moon.fill"
        }
    }
}

