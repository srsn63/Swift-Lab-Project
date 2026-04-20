import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        TabView {
            if authVM.currentUser?.role == "admin" {
                AdminDashboardView()
                    .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }
            } else if authVM.currentUser?.role == "warden" {
                WardenDashboardView()
                    .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }
            } else {
                GuardDashboardView()
                    .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }
            }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle.fill") }

            ZStack {
                AppScreenBackground()

                VStack(spacing: 24) {
                    AppHeroHeader(
                        title: "Secure Exit",
                        subtitle: "Leave the system cleanly when your shift or task is complete.",
                        icon: "rectangle.portrait.and.arrow.right",
                        tint: AppTheme.danger,
                        badgeText: "Protected"
                    )

                    AppSurfaceCard(tint: AppTheme.danger) {
                        VStack(spacing: 18) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.danger.opacity(0.12))
                                    .frame(width: 78, height: 78)
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 30, weight: .semibold))
                                    .foregroundStyle(AppTheme.danger)
                            }

                            VStack(spacing: 6) {
                                Text("Ready to sign out?")
                                    .font(.title3.bold())
                                    .foregroundStyle(AppTheme.ink)
                                Text("You will be returned to the login screen and protected actions will stop.")
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(AppTheme.inkMuted)
                            }

                            Button {
                                authVM.signOut()
                            } label: {
                                Text("Sign Out")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .background(AppTheme.danger)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    Spacer(minLength: 0)
                }
                .padding(20)
            }
            .tabItem { Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right") }
        }
        .tint(AppTheme.accent)
    }
}
