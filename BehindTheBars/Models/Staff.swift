import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI

struct ShiftDutyScheduleStatus {
    let isOnDuty: Bool
    let currentWindowStart: Date
    let currentWindowEnd: Date
    let nextDutyStart: Date
    let nextDutyEnd: Date
    let timeUntilChange: TimeInterval

    var nextChangeDate: Date {
        isOnDuty ? currentWindowEnd : nextDutyStart
    }
}

enum ShiftDutySchedule {
    static let workDuration: TimeInterval = 8 * 60 * 60
    static let restDuration: TimeInterval = 8 * 60 * 60
    static let cycleDuration: TimeInterval = workDuration + restDuration

    static func status(for anchorDate: Date, now: Date = Date()) -> ShiftDutyScheduleStatus {
        if now < anchorDate {
            return ShiftDutyScheduleStatus(
                isOnDuty: false,
                currentWindowStart: anchorDate.addingTimeInterval(-restDuration),
                currentWindowEnd: anchorDate,
                nextDutyStart: anchorDate,
                nextDutyEnd: anchorDate.addingTimeInterval(workDuration),
                timeUntilChange: anchorDate.timeIntervalSince(now)
            )
        }

        let elapsed = now.timeIntervalSince(anchorDate)
        let completedCycles = floor(elapsed / cycleDuration)
        let cycleStart = anchorDate.addingTimeInterval(completedCycles * cycleDuration)
        let phase = elapsed.truncatingRemainder(dividingBy: cycleDuration)

        if phase < workDuration {
            let currentWindowEnd = cycleStart.addingTimeInterval(workDuration)
            let nextDutyStart = cycleStart.addingTimeInterval(cycleDuration)
            return ShiftDutyScheduleStatus(
                isOnDuty: true,
                currentWindowStart: cycleStart,
                currentWindowEnd: currentWindowEnd,
                nextDutyStart: nextDutyStart,
                nextDutyEnd: nextDutyStart.addingTimeInterval(workDuration),
                timeUntilChange: currentWindowEnd.timeIntervalSince(now)
            )
        }

        let currentWindowStart = cycleStart.addingTimeInterval(workDuration)
        let currentWindowEnd = cycleStart.addingTimeInterval(cycleDuration)
        return ShiftDutyScheduleStatus(
            isOnDuty: false,
            currentWindowStart: currentWindowStart,
            currentWindowEnd: currentWindowEnd,
            nextDutyStart: currentWindowEnd,
            nextDutyEnd: currentWindowEnd.addingTimeInterval(workDuration),
            timeUntilChange: currentWindowEnd.timeIntervalSince(now)
        )
    }

    static func initialShiftName(for anchorDate: Date, calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: anchorDate)
        switch hour {
        case 6..<14:
            return "morning"
        case 14..<22:
            return "day"
        default:
            return "night"
        }
    }

    static func normalizedShiftName(_ storedShift: String?, anchorDate: Date?, fallback: String) -> String {
        if let anchorDate {
            return initialShiftName(for: anchorDate)
        }

        let value = (storedShift ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch value {
        case "morning", "day", "night":
            return value
        default:
            return fallback
        }
    }

    static func suggestedAnchorDate(for storedShift: String?, baseDate: Date = Date(), calendar: Calendar = .current) -> Date {
        let shift = normalizedShiftName(storedShift, anchorDate: nil, fallback: "day")
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)

        switch shift {
        case "morning":
            components.hour = 6
        case "day":
            components.hour = 14
        default:
            components.hour = 22
        }

        components.minute = 0
        components.second = 0

        return calendar.date(from: components) ?? baseDate
    }

    static func countdownString(to targetDate: Date, now: Date = Date()) -> String {
        let totalSeconds = max(0, Int(targetDate.timeIntervalSince(now)))
        let days = totalSeconds / 86_400
        let hours = (totalSeconds % 86_400) / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if days > 0 {
            return String(format: "%dd %02dh %02dm %02ds", days, hours, minutes, seconds)
        }

        return String(format: "%02dh %02dm %02ds", hours, minutes, seconds)
    }
}

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
    var dutyStartAt: Date?
    var isDeleted: Bool? = nil

    var dutyAnchorDate: Date? {
        dutyStartAt
    }

    var resolvedShift: String {
        ShiftDutySchedule.normalizedShiftName(shift, anchorDate: dutyAnchorDate, fallback: "morning")
    }
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

