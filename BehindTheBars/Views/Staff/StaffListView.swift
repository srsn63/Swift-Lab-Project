import SwiftUI

struct StaffListView: View {
    @StateObject private var vm = StaffViewModel()

    @State private var showingAdd = false
    @State private var editingStaff: Staff?
    @State private var detailStaff: Staff?

    var body: some View {
        List {
            Section {
                AppHeroHeader(
                    title: "Staff Directory",
                    subtitle: "Manage doctors, nurses, and support teams with live duty visibility and cleaner assignments.",
                    icon: "person.3.fill",
                    tint: AppTheme.accent,
                    badgeText: "\(vm.filtered.count)"
                )
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section {
                filtersCard
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

            if vm.filtered.isEmpty && vm.errorMessage == nil {
                Section {
                    AppEmptyStateCard(
                        title: vm.searchText.isEmpty ? "No staff found" : "No matching staff",
                        subtitle: vm.searchText.isEmpty
                            ? "Add staff members or adjust filters to begin building the prison operations team."
                            : "Try a different staff name, role, shift, or block filter.",
                        icon: "person.crop.rectangle.stack",
                        tint: AppTheme.accent
                    )
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                Section {
                    ForEach(vm.filtered) { staff in
                        Button {
                            detailStaff = staff
                        } label: {
                            StaffRowView(staff: staff, blockName: vm.blockName(for: staff.assignedBlockId))
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                guard let id = staff.id else { return }
                                Task { try? await vm.delete(staffId: id) }
                            } label: {
                                Text("Delete")
                            }

                            Button {
                                editingStaff = staff
                            } label: {
                                Text("Edit")
                            }
                            .tint(AppTheme.accent)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                Task { try? await vm.toggleActive(staff: staff) }
                            } label: {
                                Text(staff.isActive ? "Deactivate" : "Activate")
                            }
                            .tint(staff.isActive ? .orange : AppTheme.success)
                        }
                    }
                } header: {
                    Label("Team Overview", systemImage: "person.3.fill")
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppScreenBackground())
        .navigationTitle("Staff")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $vm.searchText, prompt: "Search by name")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAdd = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().fill(AppTheme.accentGradient))
                }
            }
        }
        .onAppear {
            vm.startListener()
        }
        .onDisappear {
            vm.stopListener()
        }
        .task {
            await vm.loadBlocks()
        }
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                StaffEditorView(vm: vm, existing: nil) { newStaff in
                    try await vm.create(staff: newStaff)
                }
            }
        }
        .sheet(item: $editingStaff) { staff in
            NavigationStack {
                StaffEditorView(vm: vm, existing: staff) { updated in
                    guard let id = staff.id else { return }
                    try await vm.update(staffId: id, staff: updated)
                }
            }
        }
        .sheet(item: $detailStaff) { staff in
            NavigationStack {
                StaffDetailView(staff: staff, vm: vm)
            }
        }
    }

    private var filtersCard: some View {
        AppSurfaceCard(tint: AppTheme.accent, padding: 16) {
            VStack(alignment: .leading, spacing: 16) {
                Label("Filters", systemImage: "line.3.horizontal.decrease.circle.fill")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(title: "All", isSelected: vm.selectedType == nil) {
                            vm.selectedType = nil
                        }
                        ForEach(StaffType.allCases) { type in
                            FilterChip(
                                title: type.displayName,
                                isSelected: vm.selectedType == type
                            ) {
                                vm.selectedType = (vm.selectedType == type) ? nil : type
                            }
                        }
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(ShiftType.allCases) { shift in
                            FilterChip(
                                title: shift.displayName,
                                icon: shift.icon,
                                isSelected: vm.selectedShift == shift
                            ) {
                                vm.selectedShift = (vm.selectedShift == shift) ? nil : shift
                            }
                        }

                        Menu {
                            Button("All Blocks") { vm.selectedBlockId = nil }
                            ForEach(vm.blocks) { block in
                                Button(block.name) { vm.selectedBlockId = block.id }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "building.2")
                                    .font(.caption2)
                                Text(vm.selectedBlockId == nil ? "All Blocks" : vm.blockName(for: vm.selectedBlockId ?? ""))
                                    .font(.caption.bold())
                                    .lineLimit(1)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .foregroundStyle(vm.selectedBlockId == nil ? AppTheme.ink : Color.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(vm.selectedBlockId == nil ? AnyShapeStyle(AppTheme.surfaceInteractive) : AnyShapeStyle(AppTheme.accentGradient))
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .strokeBorder(vm.selectedBlockId == nil ? AppTheme.surfaceBorder : Color.white.opacity(0.16), lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
    }
}

struct StaffRowView: View {
    let staff: Staff
    let blockName: String

    private var staffType: StaffType {
        StaffType(rawValue: staff.staffType) ?? .other
    }

    private var shiftLabel: String {
        ShiftType(rawValue: staff.resolvedShift)?.displayName ?? staff.resolvedShift.capitalized
    }

    var body: some View {
        AppSurfaceCard(tint: staffType.color, padding: 16) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(staffType.color.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: staffType.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(staffType.color)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(staff.fullName.isEmpty ? "Unnamed Staff" : staff.fullName)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.ink)
                        if !staff.isActive {
                            StatusBadge(text: "Inactive", color: AppTheme.danger, small: true)
                        }
                    }

                    HStack(spacing: 10) {
                        Label(blockName, systemImage: "building.2")
                            .lineLimit(1)
                        Label(shiftLabel, systemImage: "clock")
                            .lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.inkMuted)

                    if let dutyStartAt = staff.dutyAnchorDate {
                        StaffDutyStatusLabel(dutyStartAt: dutyStartAt)
                    } else {
                        Text("Duty schedule not assigned")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.inkMuted)
                    }
                }

                Spacer()

                StatusBadge(
                    text: staffType.displayName,
                    color: staffType.color,
                    small: true
                )
            }
        }
    }
}

private struct StaffDutyStatusLabel: View {
    let dutyStartAt: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(primaryText(now: context.date))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(isOnDuty(now: context.date) ? AppTheme.success : AppTheme.warning)
        }
    }

    private func status(now: Date) -> ShiftDutyScheduleStatus {
        ShiftDutySchedule.status(for: dutyStartAt, now: now)
    }

    private func isOnDuty(now: Date) -> Bool {
        status(now: now).isOnDuty
    }

    private func primaryText(now: Date) -> String {
        let currentStatus = status(now: now)
        let countdown = ShiftDutySchedule.countdownString(to: currentStatus.nextChangeDate, now: now)

        if currentStatus.isOnDuty {
            return "On duty, ends in \(countdown)"
        }

        return "Off duty, starts in \(countdown)"
    }
}

struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(title)
                    .font(.caption.bold())
            }
            .foregroundStyle(isSelected ? Color.white : AppTheme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(AppTheme.surfaceInteractive))
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(isSelected ? Color.white.opacity(0.16) : AppTheme.surfaceBorder, lineWidth: 1)
            )
            .shadow(color: isSelected ? AppTheme.shadow.opacity(0.8) : .clear, radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}
