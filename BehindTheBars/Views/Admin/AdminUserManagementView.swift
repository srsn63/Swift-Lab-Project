import SwiftUI

struct AdminUserManagementView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.accent.opacity(0.4))
            Text("User Management")
                .font(.headline)
            Text("Coming soon")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Manage Users")
    }
}
