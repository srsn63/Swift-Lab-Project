import SwiftUI

struct GuardShiftScheduleView: View {
    @StateObject private var vm = GuardListViewModel()
    @StateObject private var blocksVM = BlocksDirectoryViewModel()

    private var morning: [User] {
        vm.guards.filter { $0.resolvedShift == "morning" }
    }

    private var day: [User] {
        vm.guards.filter { $0.resolvedShift == "day" }
    }

    private var night: [User] {
        vm.guards.filter { $0.resolvedShift == "night" }
    }

    var body: some View {
        List {
            summaryCard

            guardSection(title: "Morning", icon: "sunrise.fill", color: .orange, guards: morning)
            guardSection(title: "Day", icon: "sun.max.fill", color: AppTheme.accent, guards: day)
            guardSection(title: "Night", icon: "moon.fill", color: .indigo, guards: night)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Guard Shifts")
        .task { await blocksVM.load() }
        .onAppear { vm.startListener() }
        .onDisappear { vm.stopListener() }
    }

    private var summaryCard: some View {
        Section {
            HStack {
                statChip(title: "Morning", count: morning.count, color: .orange)
                Spacer()
                statChip(title: "Day", count: day.count, color: AppTheme.accent)
                Spacer()
                statChip(title: "Night", count: night.count, color: .indigo)
            }
        }
    }

    private func statChip(title: String, count: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(count)")
                .font(.title3.bold())
                .foregroundColor(color)
        }
    }

    @ViewBuilder
    private func guardSection(title: String, icon: String, color: Color, guards: [User]) -> some View {
        Section {
            if guards.isEmpty {
                Text("No guards assigned")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(guards) { guardUser in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(color.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: "shield.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(color)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(displayName(for: guardUser))
                                .font(.subheadline.bold())
                            Text(guardUser.email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let block = guardUser.assignedBlockId, !block.isEmpty {
                            StatusBadge(text: getBlockName(id: block), color: AppTheme.accent, small: true)
                        } else {
                            StatusBadge(text: "Unassigned", color: .secondary, small: true)
                        }
                    }
                    .padding(.vertical, 3)

                    if let dutyStartAt = guardUser.dutyAnchorDate {
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            let dutyStatus = ShiftDutySchedule.status(for: dutyStartAt, now: context.date)
                            Text(
                                dutyStatus.isOnDuty
                                    ? "On duty, ends in \(ShiftDutySchedule.countdownString(to: dutyStatus.nextChangeDate, now: context.date))"
                                    : "Off duty, starts in \(ShiftDutySchedule.countdownString(to: dutyStatus.nextChangeDate, now: context.date))"
                            )
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(dutyStatus.isOnDuty ? AppTheme.success : AppTheme.warning)
                        }
                    } else {
                        Text("Duty schedule not assigned")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundColor(color)
        }
    }

    private func displayName(for user: User) -> String {
        let name = (user.fullName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? user.email : name
    }

    private func getBlockName(id: String) -> String {
        blocksVM.blocks.first(where: { $0.id == id })?.name ?? id
    }
}
