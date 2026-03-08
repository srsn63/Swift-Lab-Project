import SwiftUI

struct WardenDashboardView: View {
    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    NavigationLink { InmateListView() } label: {
                        DashboardCard(
                            title: "Inmates",
                            subtitle: "Manage all inmates",
                            icon: "person.crop.rectangle.stack.fill",
                            color: AppTheme.accent
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink { GuardListView() } label: {
                        DashboardCard(
                            title: "Guards",
                            subtitle: "Manage guard staff",
                            icon: "shield.lefthalf.filled",
                            color: .purple
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink { ReportIncidentView() } label: {
                        DashboardCard(
                            title: "Report",
                            subtitle: "File a new incident",
                            icon: "exclamationmark.bubble.fill",
                            color: AppTheme.danger
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink { IncidentListView() } label: {
                        DashboardCard(
                            title: "Incidents",
                            subtitle: "View all reports",
                            icon: "list.clipboard.fill",
                            color: AppTheme.warning
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Warden")
        }
    }
}
