import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        TabView {
            if authVM.currentUser?.role == "admin" {
                AdminDashboardView()
                    .tabItem { Label("Admin", systemImage: "shield.lefthalf.filled") }
            } else if authVM.currentUser?.role == "warden" {
                WardenDashboardView()
                    .tabItem { Label("Warden", systemImage: "person.crop.rectangle") }
            } else {
                GuardDashboardView()
                    .tabItem { Label("Guard", systemImage: "shield") }
            }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle") }

            Button { authVM.signOut() } label: { Text("Logout") }
                .tabItem { Label("Logout", systemImage: "rectangle.portrait.and.arrow.right") }
        }
    }
}
