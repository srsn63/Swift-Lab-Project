import SwiftUI

// MARK: - Color Palette & Theme

enum AppTheme {
    // Primary palette
    static let primary = Color(red: 0.11, green: 0.16, blue: 0.25)
    static let primaryLight = Color(red: 0.17, green: 0.24, blue: 0.36)
    static let accent = Color(red: 0.27, green: 0.54, blue: 0.87)
    static let accentLight = Color(red: 0.38, green: 0.62, blue: 0.93)

    // Semantic
    static let success = Color(red: 0.18, green: 0.75, blue: 0.35)
    static let warning = Color(red: 0.95, green: 0.68, blue: 0.0)
    static let danger = Color(red: 0.90, green: 0.22, blue: 0.21)

    // Gradients
    static let primaryGradient = LinearGradient(
        colors: [primary, primaryLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [accent, accentLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let headerGradient = LinearGradient(
        colors: [
            Color(red: 0.09, green: 0.13, blue: 0.22),
            Color(red: 0.14, green: 0.21, blue: 0.33),
            Color(red: 0.11, green: 0.17, blue: 0.28)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Security level colors
    static func securityColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "low": return .green
        case "medium": return .orange
        case "high": return .red
        default: return .gray
        }
    }

    // Severity colors
    static func severityColor(_ severity: Int) -> Color {
        switch severity {
        case 1: return .green
        case 2: return .teal
        case 3: return .orange
        case 4: return Color(red: 1.0, green: 0.4, blue: 0.0)
        case 5: return .red
        default: return .gray
        }
    }

    static func severityLabel(_ severity: Int) -> String {
        switch severity {
        case 1: return "Minor"
        case 2: return "Low"
        case 3: return "Moderate"
        case 4: return "Serious"
        case 5: return "Critical"
        default: return "Unknown"
        }
    }
}

// MARK: - Reusable Components

struct DashboardCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 3)
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color
    var small: Bool = false

    var body: some View {
        Text(text)
            .font(.system(size: small ? 10 : 11, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, small ? 6 : 8)
            .padding(.vertical, small ? 3 : 4)
            .background(color.opacity(0.12))
            .cornerRadius(6)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}
