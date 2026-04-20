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
            Section {
                AppHeroHeader(
                    title: "Guard Shift Schedule",
                    subtitle: "Monitor every duty group with live countdowns based on the 8-hour work and 8-hour rest cycle.",
                    icon: "clock.badge.checkmark",
                    tint: AppTheme.accent,
                    badgeText: "\(vm.guards.count)"
                )
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section {
                summaryCard
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if let err = vm.errorMessage {
                Section {
                    AppMessageBanner(text: err, tint: AppTheme.danger)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            guardSection(title: "Morning", icon: "sunrise.fill", color: .orange, guards: morning)
            guardSection(title: "Day", icon: "sun.max.fill", color: AppTheme.accent, guards: day)
            guardSection(title: "Night", icon: "moon.fill", color: .indigo, guards: night)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppScreenBackground())
        .navigationTitle("Guard Shifts")
        .navigationBarTitleDisplayMode(.inline)
        .task { await blocksVM.load() }
        .onAppear { vm.startListener() }
        .onDisappear { vm.stopListener() }
    }

    private var summaryCard: some View {
        AppSurfaceCard(tint: AppTheme.accent) {
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.inkMuted)
            Text("\(count)")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text("guards")
                .font(.caption)
                .foregroundStyle(AppTheme.inkMuted)
        }
    }

    @ViewBuilder
    private func guardSection(title: String, icon: String, color: Color, guards: [User]) -> some View {
        Section {
            if guards.isEmpty {
                AppEmptyStateCard(
                    title: "No guards assigned",
                    subtitle: "No guards currently resolve into the \(title.lowercased()) shift group.",
                    icon: icon,
                    tint: color
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(guards) { guardUser in
                    ShiftGuardRowCard(
                        user: guardUser,
                        tint: color,
                        blockName: getBlockName(id: guardUser.assignedBlockId ?? ""),
                        displayName: displayName(for: guardUser)
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
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
        blocksVM.blocks.first(where: { $0.id == id })?.name ?? (id.isEmpty ? "Unassigned" : id)
    }
}

private struct ShiftGuardRowCard: View {
    let user: User
    let tint: Color
    let blockName: String
    let displayName: String

    var body: some View {
        AppSurfaceCard(tint: tint, padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(tint.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: "shield.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(tint)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayName)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.ink)
                        Text(user.email)
                            .font(.caption)
                            .foregroundStyle(AppTheme.inkMuted)
                    }

                    Spacer()

                    StatusBadge(
                        text: (user.assignedBlockId ?? "").isEmpty ? "Unassigned" : blockName,
                        color: (user.assignedBlockId ?? "").isEmpty ? .secondary : AppTheme.accent,
                        small: true
                    )
                }

                if let dutyStartAt = user.dutyAnchorDate {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let dutyStatus = ShiftDutySchedule.status(for: dutyStartAt, now: context.date)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(
                                dutyStatus.isOnDuty
                                    ? "On duty, ends in \(ShiftDutySchedule.countdownString(to: dutyStatus.nextChangeDate, now: context.date))"
                                    : "Off duty, starts in \(ShiftDutySchedule.countdownString(to: dutyStatus.nextChangeDate, now: context.date))"
                            )
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(dutyStatus.isOnDuty ? AppTheme.success : AppTheme.warning)

                            Text(
                                dutyStatus.isOnDuty
                                    ? "Current window: \(dutyStatus.currentWindowStart.formatted(date: .omitted, time: .shortened)) to \(dutyStatus.currentWindowEnd.formatted(date: .omitted, time: .shortened))"
                                    : "Next window: \(dutyStatus.nextDutyStart.formatted(date: .abbreviated, time: .shortened)) to \(dutyStatus.nextDutyEnd.formatted(date: .abbreviated, time: .shortened))"
                            )
                            .font(.caption2)
                            .foregroundStyle(AppTheme.inkMuted)
                        }
                    }
                } else {
                    Text("Duty schedule not assigned")
                        .font(.caption)
                        .foregroundStyle(AppTheme.inkMuted)
                }
            }
        }
    }
}
