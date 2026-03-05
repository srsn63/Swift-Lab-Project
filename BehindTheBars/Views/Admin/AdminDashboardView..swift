import SwiftUI

struct AdminDashboardView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Approvals") {
                    AdminApprovalsView()
                }

                NavigationLink("Blocks") {
                    BlockManagerView()
                }

                NavigationLink("Manage Users") {
                    AdminUserManagementView()
                }
            }
            .navigationTitle("Admin")
        }
    }
}
