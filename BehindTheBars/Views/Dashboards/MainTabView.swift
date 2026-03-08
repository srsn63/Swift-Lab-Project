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

            VStack(spacing: 20) {
                Spacer()
                ZStack {
                    Circle()
                        .fill(AppTheme.danger.opacity(0.1))
                        .frame(width: 80, height: 80)
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.danger)
                }
                Text("Sign Out")
                    .font(.title3.bold())
                Text("You will be returned to the login screen")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button {
                    authVM.signOut()
                } label: {
                    Text("Sign Out")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200)
                        .padding(.vertical, 14)
                        .background(AppTheme.danger)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
                Spacer()
            }
            .tabItem { Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right") }
        }
        .tint(AppTheme.accent)
    }
}
