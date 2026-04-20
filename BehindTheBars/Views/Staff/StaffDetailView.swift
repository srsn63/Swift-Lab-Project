import SwiftUI

struct StaffDetailView: View {
    let staff: Staff
    @ObservedObject var vm: StaffViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showEdit = false

    private var staffType: StaffType {
        StaffType(rawValue: staff.staffType) ?? .other
    }

    private var shiftType: ShiftType {
        ShiftType(rawValue: staff.resolvedShift) ?? .morning
    }

    private var blockLabel: String {
        vm.blockName(for: staff.assignedBlockId)
    }

    var body: some View {
        ZStack {
            AppScreenBackground()

            ScrollView {
                VStack(spacing: 18) {
                    AppHeroHeader(
                        title: staff.fullName.isEmpty ? "Unnamed Staff" : staff.fullName,
                        subtitle: "\(staffType.displayName) assigned to \(blockLabel)",
                        icon: staffType.icon,
                        tint: staffType.color,
                        badgeText: staff.isActive ? "Active" : "Inactive"
                    )

                    AppSurfaceCard(tint: staffType.color) {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Overview", systemImage: "person.text.rectangle")
                                .font(.caption.bold())
                                .foregroundColor(staffType.color)

                            InfoRow(label: "Full Name", value: staff.fullName.isEmpty ? "Not provided" : staff.fullName)
                            InfoRow(label: "Type", value: staffType.displayName)
                            InfoRow(label: "Phone", value: staff.phoneNumber.isEmpty ? "Not provided" : staff.phoneNumber)
                            InfoRow(label: "Hire Date", value: staff.hireDate.formatted(date: .abbreviated, time: .omitted))
                            InfoRow(label: "Status", value: staff.isActive ? "Active" : "Inactive")
                        }
                    }

                    AppSurfaceCard(tint: AppTheme.accent) {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Assignment", systemImage: "building.2")
                                .font(.caption.bold())
                                .foregroundColor(AppTheme.accent)

                            InfoRow(label: "Block", value: blockLabel)
                            InfoRow(label: "Shift", value: shiftType.displayName)
                            if let dutyStartAt = staff.dutyAnchorDate {
                                InfoRow(label: "First Duty Start", value: dutyStartAt.formatted(date: .abbreviated, time: .shortened))
                            } else {
                                InfoRow(label: "First Duty Start", value: "Not assigned")
                            }
                        }
                    }

                    AppSurfaceCard(tint: staff.isActive ? AppTheme.success : AppTheme.warning) {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Live Duty Status", systemImage: "clock.badge.checkmark")
                                .font(.caption.bold())
                                .foregroundColor(staff.isActive ? AppTheme.success : AppTheme.warning)

                            if let dutyStartAt = staff.dutyAnchorDate {
                                StaffLiveDutyStatusView(dutyStartAt: dutyStartAt)
                            } else {
                                AppMessageBanner(
                                    text: "A duty schedule has not been assigned yet.",
                                    tint: AppTheme.warning,
                                    icon: "clock.badge.exclamationmark"
                                )
                            }
                        }
                    }

                    if !staff.notes.isEmpty {
                        AppSurfaceCard(tint: AppTheme.primaryLight) {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("Notes", systemImage: "note.text")
                                    .font(.caption.bold())
                                    .foregroundColor(AppTheme.primaryLight)

                                Text(staff.notes)
                                    .font(.body)
                                    .foregroundStyle(AppTheme.inkMuted)
                            }
                        }
                    }

                    VStack(spacing: 12) {
                        Button {
                            showEdit = true
                        } label: {
                            Label("Edit Profile", systemImage: "pencil")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(AppTheme.accentGradient)
                                )
                        }

                        Button {
                            Task {
                                try? await vm.toggleActive(staff: staff)
                                dismiss()
                            }
                        } label: {
                            Label(
                                staff.isActive ? "Deactivate" : "Activate",
                                systemImage: staff.isActive ? "xmark.circle" : "checkmark.circle"
                            )
                            .font(.subheadline.bold())
                            .foregroundColor(staff.isActive ? AppTheme.danger : AppTheme.success)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill((staff.isActive ? AppTheme.danger : AppTheme.success).opacity(0.12))
                            )
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Staff Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if vm.blocks.isEmpty {
                await vm.loadBlocks()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .sheet(isPresented: $showEdit) {
            NavigationStack {
                StaffEditorView(vm: vm, existing: staff) { updated in
                    guard let id = staff.id else { return }
                    try await vm.update(staffId: id, staff: updated)
                }
            }
        }
    }
}

private struct StaffLiveDutyStatusView: View {
    let dutyStartAt: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 12) {
                StatusBadge(
                    text: isOnDuty(now: context.date) ? "On Duty" : "Off Duty",
                    color: isOnDuty(now: context.date) ? AppTheme.success : AppTheme.warning
                )

                Text(isOnDuty(now: context.date) ? "Duty ends in" : "Next duty starts in")
                    .font(.caption)
                    .foregroundStyle(AppTheme.inkMuted)

                Text(countdown(now: context.date))
                    .font(.system(size: 24, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(AppTheme.ink)

                Text(windowText(now: context.date))
                    .font(.caption)
                    .foregroundStyle(AppTheme.inkMuted)
            }
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
