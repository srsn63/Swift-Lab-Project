import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.userSession == nil {
                LoginView()
            } else if authVM.currentUser == nil {
                ZStack {
                    AppScreenBackground()

                    VStack(spacing: 24) {
                        AppSurfaceCard(tint: AppTheme.accent, padding: 26) {
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.accent.opacity(0.12))
                                        .frame(width: 86, height: 86)
                                    Image(systemName: "building.columns.fill")
                                        .font(.system(size: 38, weight: .semibold))
                                        .foregroundStyle(AppTheme.accent)
                                }

                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(AppTheme.accent)

                                VStack(spacing: 6) {
                                    Text("Loading profile...")
                                        .font(.title3.bold())
                                        .foregroundStyle(AppTheme.ink)
                                    Text("Preparing your secure workspace")
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.inkMuted)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(24)
                }
                .task { await authVM.fetchCurrentUser() }
            } else if authVM.canEnterApp == false {
                PendingApprovalView()
            } else {
                MainTabView()
            }
        }
    }
}
