import SwiftUI

struct GuardDashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                dutyStatusSection

                LazyVGrid(columns: columns, spacing: 16) {
                    NavigationLink { InmateListView() } label: {
                        DashboardCard(
                            title: "Inmates",
                            subtitle: "View assigned inmates",
                            icon: "person.crop.rectangle.stack.fill",
                            color: AppTheme.accent
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

                    NavigationLink { MedicalRecordsView(accessMode: .guardManage) } label: {
                        DashboardCard(
                            title: "Medical",
                            subtitle: "Assign doctors and track treatment",
                            icon: "cross.case.fill",
                            color: .red
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .padding(.top, authVM.currentUser?.dutyAnchorDate == nil ? 0 : 4)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Guard")
        }
    }

    @ViewBuilder
    private var dutyStatusSection: some View {
        if let currentUser = authVM.currentUser {
            if let dutyStartAt = currentUser.dutyAnchorDate {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let dutyStatus = ShiftDutySchedule.status(for: dutyStartAt, now: context.date)

                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(dutyStatus.isOnDuty ? "You are on duty now" : "You are currently off duty")
                                    .font(.headline.bold())
                                Text(dutyStatus.isOnDuty ? "Duty ends in" : "Next duty starts in")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            StatusBadge(
                                text: dutyStatus.isOnDuty ? "On Duty" : "Off Duty",
                                color: dutyStatus.isOnDuty ? AppTheme.success : AppTheme.warning
                            )
                        }

                        Text(ShiftDutySchedule.countdownString(to: dutyStatus.nextChangeDate, now: context.date))
                            .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())

                        VStack(alignment: .leading, spacing: 6) {
                            Text(
                                dutyStatus.isOnDuty
                                    ? "Current duty window: \(dutyStatus.currentWindowStart.formatted(date: .omitted, time: .shortened)) to \(dutyStatus.currentWindowEnd.formatted(date: .omitted, time: .shortened))"
                                    : "Next duty window: \(dutyStatus.nextDutyStart.formatted(date: .abbreviated, time: .shortened)) to \(dutyStatus.nextDutyEnd.formatted(date: .abbreviated, time: .shortened))"
                            )
                            Text("Cycle rule: 8 hours on duty, 8 hours rest.")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill((dutyStatus.isOnDuty ? AppTheme.success : AppTheme.warning).opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke((dutyStatus.isOnDuty ? AppTheme.success : AppTheme.warning).opacity(0.28), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Duty schedule not assigned")
                        .font(.headline.bold())
                    Text("Ask an admin or warden to set your first duty start date and time to enable the live duty countdown.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
    }
}
