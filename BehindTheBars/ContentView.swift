import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.userSession == nil {
                LoginView()
            } else if authVM.currentUser == nil {
                ZStack {
                    AppTheme.headerGradient.ignoresSafeArea()
                    VStack(spacing: 20) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.white.opacity(0.8))
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                        Text("Loading profile\u{2026}")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.subheadline)
                    }
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
