import SwiftUI

struct GuardDashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    AppHeroHeader(
                        title: "Guard Dashboard",
                        subtitle: "Track your duty status and respond quickly to inmate, incident, and medical tasks.",
                        icon: "shield.fill",
                        tint: AppTheme.accent,
                        badgeText: "Guard"
                    )

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
                }
                .padding(20)
            }
            .background(AppScreenBackground())
            .navigationTitle("Guard")
        }
    }

    @ViewBuilder
    private var dutyStatusSection: some View {
        if let currentUser = authVM.currentUser {
            if let dutyStartAt = currentUser.dutyAnchorDate {
                GuardDashboardDutyStatusView(dutyStartAt: dutyStartAt)
            } else {
                AppMessageBanner(
                    text: "Duty schedule not assigned. Ask an admin or warden to set your first duty start date and time.",
                    tint: AppTheme.warning,
                    icon: "clock.badge.exclamationmark"
                )
            }
        }
    }
}

private struct GuardDashboardDutyStatusView: View {
    let dutyStartAt: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isOnDuty(now: context.date) ? "You are on duty now" : "You are currently off duty")
                            .font(.headline.bold())
                        Text(isOnDuty(now: context.date) ? "Duty ends in" : "Next duty starts in")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    StatusBadge(
                        text: isOnDuty(now: context.date) ? "On Duty" : "Off Duty",
                        color: isOnDuty(now: context.date) ? AppTheme.success : AppTheme.warning
                    )
                }

                Text(countdown(now: context.date))
                    .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())

                VStack(alignment: .leading, spacing: 6) {
                    Text(windowText(now: context.date))
                    Text("Cycle rule: 8 hours on duty, 8 hours rest.")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppTheme.tintedSurface(isOnDuty(now: context.date) ? AppTheme.success : AppTheme.warning))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke((isOnDuty(now: context.date) ? AppTheme.success : AppTheme.warning).opacity(0.22), lineWidth: 1)
            )
            .shadow(color: AppTheme.shadow, radius: 18, y: 10)
        }
    }

    private func status(now: Date) -> ShiftDutyScheduleStatus {
        ShiftDutySchedule.status(for: dutyStartAt, now: now)
    }

    private func isOnDuty(now: Date) -> Bool {
        status(now: now).isOnDuty
    }

    private func countdown(now: Date) -> String {
        let currentStatus = status(now: now)
        return ShiftDutySchedule.countdownString(to: currentStatus.nextChangeDate, now: now)
    }

    private func windowText(now: Date) -> String {
        let currentStatus = status(now: now)

        if currentStatus.isOnDuty {
            return "Current duty window: \(currentStatus.currentWindowStart.formatted(date: .omitted, time: .shortened)) to \(currentStatus.currentWindowEnd.formatted(date: .omitted, time: .shortened))"
        }

        return "Next duty window: \(currentStatus.nextDutyStart.formatted(date: .abbreviated, time: .shortened)) to \(currentStatus.nextDutyEnd.formatted(date: .abbreviated, time: .shortened))"
    }
}
