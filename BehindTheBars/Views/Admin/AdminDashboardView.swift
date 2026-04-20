import SwiftUI

struct AdminDashboardView: View {
    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    AppHeroHeader(
                        title: "Admin Command",
                        subtitle: "Oversee approvals, users, staffing, and operational control from one secure hub.",
                        icon: "building.columns.fill",
                        tint: AppTheme.accent,
                        badgeText: "Admin"
                    )

                    LazyVGrid(columns: columns, spacing: 16) {
                        NavigationLink { AdminApprovalsView() } label: {
                            DashboardCard(
                                title: "Approvals",
                                subtitle: "Review pending accounts",
                                icon: "checkmark.shield.fill",
                                color: AppTheme.success
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink { BlockManagerView() } label: {
                            DashboardCard(
                                title: "Blocks",
                                subtitle: "Manage prison blocks",
                                icon: "building.2.fill",
                                color: AppTheme.accent
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink { AdminUserManagementView() } label: {
                            DashboardCard(
                                title: "Users",
                                subtitle: "Manage staff accounts",
                                icon: "person.2.fill",
                                color: .purple
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink { IncidentListView() } label: {
                            DashboardCard(
                                title: "Incidents",
                                subtitle: "View all reports",
                                icon: "exclamationmark.triangle.fill",
                                color: AppTheme.warning
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink { StaffListView() } label: {
                            DashboardCard(
                                title: "Staff",
                                subtitle: "Manage prison staff",
                                icon: "person.3.fill",
                                color: .teal
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .background(AppScreenBackground())
            .navigationTitle("Admin")
        }
    }
}
