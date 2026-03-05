import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.userSession == nil {
                LoginView()
            } else if authVM.currentUser == nil {
                ProgressView("Loading profile...")
                    .task { await authVM.fetchCurrentUser() }
            } else if authVM.canEnterApp == false {
                PendingApprovalView()
            } else {
                MainTabView()
            }
        }
    }
}
