import SwiftUI

enum AppTheme {
    static let primary = Color(red: 0.09, green: 0.14, blue: 0.23)
    static let primaryLight = Color(red: 0.15, green: 0.24, blue: 0.38)
    static let accent = Color(red: 0.22, green: 0.56, blue: 0.90)
    static let accentLight = Color(red: 0.42, green: 0.72, blue: 0.98)

    static let success = Color(red: 0.18, green: 0.72, blue: 0.42)
    static let warning = Color(red: 0.95, green: 0.67, blue: 0.13)
    static let danger = Color(red: 0.84, green: 0.27, blue: 0.25)

    static let ink = Color(red: 0.10, green: 0.15, blue: 0.23)
    static let inkMuted = Color(red: 0.38, green: 0.45, blue: 0.55)
    static let canvasTop = Color(red: 0.95, green: 0.97, blue: 1.00)
    static let canvasBottom = Color(red: 0.91, green: 0.94, blue: 0.98)
    static let surface = Color(uiColor: .secondarySystemBackground)
    static let surfaceElevated = Color(uiColor: .systemBackground)
    static let surfaceInteractive = Color(red: 0.94, green: 0.96, blue: 0.99)
    static let surfaceBorder = Color.white.opacity(0.78)
    static let shadow = Color(red: 0.06, green: 0.10, blue: 0.16).opacity(0.14)

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
            Color(red: 0.08, green: 0.12, blue: 0.20),
            Color(red: 0.11, green: 0.19, blue: 0.31),
            Color(red: 0.16, green: 0.28, blue: 0.45)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let screenGradient = LinearGradient(
        colors: [canvasTop, canvasBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func tintedSurface(_ tint: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                surfaceElevated,
                tint.opacity(0.12),
                surface
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func securityColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "low": return .green
        case "medium": return .orange
        case "high": return .red
        default: return .gray
        }
    }

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

    static func roleColor(_ role: String?) -> Color {
        switch role {
        case "admin": return .purple
        case "warden": return accent
        case "guard": return success
        default: return .secondary
        }
    }
}

struct AppScreenBackground: View {
    var body: some View {
        ZStack {
            AppTheme.screenGradient.ignoresSafeArea()

            Circle()
                .fill(AppTheme.accent.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 48)
                .offset(x: -110, y: -260)

            Circle()
                .fill(AppTheme.primaryLight.opacity(0.14))
                .frame(width: 320, height: 320)
                .blur(radius: 56)
                .offset(x: 150, y: -180)
        }
    }
}

struct AppSurfaceCard<Content: View>: View {
    let tint: Color
    let padding: CGFloat
    let content: Content

    init(tint: Color = AppTheme.accent, padding: CGFloat = 18, @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppTheme.tintedSurface(tint))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(AppTheme.surfaceBorder, lineWidth: 1)
            )
            .shadow(color: AppTheme.shadow, radius: 20, y: 10)
    }
}

struct AppHeroHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    var tint: Color = AppTheme.accent
    var badgeText: String? = nil

    var body: some View {
        AppSurfaceCard(tint: tint) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(tint.opacity(0.14))
                            .frame(width: 58, height: 58)
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(tint)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.ink)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.inkMuted)
                    }

                    Spacer()

                    if let badgeText {
                        StatusBadge(text: badgeText, color: tint)
                    }
                }
            }
        }
    }
}

struct AppMessageBanner: View {
    let text: String
    let tint: Color
    var icon: String = "exclamationmark.triangle.fill"

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .font(.system(size: 15, weight: .semibold))
            Text(text)
                .font(.footnote.weight(.medium))
                .foregroundStyle(AppTheme.ink)
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.tintedSurface(tint))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(tint.opacity(0.18), lineWidth: 1)
        )
    }
}

struct AppEmptyStateCard: View {
    let title: String
    let subtitle: String
    let icon: String
    var tint: Color = AppTheme.accent

    var body: some View {
        AppSurfaceCard(tint: tint, padding: 24) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.12))
                        .frame(width: 64, height: 64)
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(tint)
                }

                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.ink)

                Text(subtitle)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.inkMuted)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct DashboardCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        AppSurfaceCard(tint: color) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(color.opacity(0.15))
                            .frame(width: 52, height: 52)
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(color)
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.inkMuted.opacity(0.8))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.inkMuted)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
        }
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color
    var small: Bool = false

    var body: some View {
        Text(text)
            .font(.system(size: small ? 10 : 11, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, small ? 9 : 11)
            .padding(.vertical, small ? 5 : 6)
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(0.12))
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(color.opacity(0.18), lineWidth: 1)
            )
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.inkMuted)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}
