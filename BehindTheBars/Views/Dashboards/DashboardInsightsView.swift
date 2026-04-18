import SwiftUI

struct DashboardInsightsView: View {
    @StateObject private var vm = DashboardStatsViewModel()

    var body: some View {
        VStack(spacing: 12) {
            if vm.autoReleaseAlerts > 0 {
                HStack(spacing: 10) {
                    Image(systemName: "bell.badge.fill")
                        .foregroundColor(AppTheme.warning)
                    Text("Release Alerts: \(vm.autoReleaseAlerts) inmate(s) reached or passed release date")
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.warning)
                    Spacer()
                }
                .padding(12)
                .background(AppTheme.warning.opacity(0.12))
                .cornerRadius(10)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                metricCard(title: "Total Inmates", value: "\(vm.totalInmates)", icon: "person.crop.rectangle.stack", color: AppTheme.accent)
                metricCard(title: "Active Incidents", value: "\(vm.activeIncidents)", icon: "exclamationmark.triangle", color: AppTheme.danger)
                metricCard(title: "Staff Count", value: "\(vm.staffCount)", icon: "person.3", color: .teal)
                metricCard(title: "Guards On Duty", value: "\(vm.guardsOnDuty)", icon: "shield.fill", color: .indigo)
            }

            if !vm.inmatesPerBlock.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Inmates Per Block", systemImage: "building.2")
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.accent)

                    ForEach(vm.inmatesPerBlock, id: \.name) { item in
                        HStack {
                            Text(item.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(item.count)")
                                .font(.caption.bold())
                        }
                    }
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(10)
            }

            if !vm.incidentByDay.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Incidents Per Day (7d)", systemImage: "chart.bar")
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.accent)

                    ForEach(vm.incidentByDay, id: \.day) { item in
                        HStack {
                            Text(item.day)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(item.count)")
                                .font(.caption.bold())
                        }
                    }
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(10)
            }
        }
        .task {
            await vm.load()
        }
    }

    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.primary)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}
