import SwiftUI

struct StaffListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = StaffViewModel()

    @State private var showingAdd = false
    @State private var editingStaff: Staff?
    @State private var detailStaff: Staff?

    var body: some View {
        VStack(spacing: 0) {
            // Category filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
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
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Color(UIColor.systemGroupedBackground))

            // Shift filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ShiftType.allCases) { shift in
                        FilterChip(
                            title: shift.displayName,
                            icon: shift.icon,
                            isSelected: vm.selectedShift == shift
                        ) {
                            vm.selectedShift = (vm.selectedShift == shift) ? nil : shift
                        }
                    }

                    Divider().frame(height: 20)

                    // Block filter
                    Menu {
                        Button("All Blocks") { vm.selectedBlockId = nil }
                        ForEach(vm.blocks) { block in
                            Button(block.name) { vm.selectedBlockId = block.id }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "building.2")
                                .font(.caption2)
                            Text(vm.selectedBlockId == nil ? "All Blocks" : vm.blockName(for: vm.selectedBlockId ?? ""))
                                .font(.caption.bold())
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundColor(vm.selectedBlockId != nil ? .white : AppTheme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(vm.selectedBlockId != nil ? AppTheme.accent : AppTheme.accent.opacity(0.12))
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .background(Color(UIColor.systemGroupedBackground))

            // Staff list
            List {
                if let err = vm.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppTheme.danger)
                        Text(err)
                            .foregroundStyle(AppTheme.danger)
                            .font(.footnote)
                    }
                }

                if vm.filtered.isEmpty && vm.errorMessage == nil {
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "person.crop.rectangle.stack")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary.opacity(0.4))
                            Text(vm.searchText.isEmpty ? "No staff found" : "No results for \"\(vm.searchText)\"")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 40)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                ForEach(vm.filtered) { staff in
                    Button {
                        detailStaff = staff
                    } label: {
                        StaffRowView(staff: staff, blockName: vm.blockName(for: staff.assignedBlockId))
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            guard let id = staff.id else { return }
                            Task { try? await vm.delete(staffId: id) }
                        } label: { Text("Delete") }

                        Button {
                            editingStaff = staff
                        } label: { Text("Edit") }
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
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Staff")
        .searchable(text: $vm.searchText, prompt: "Search by name")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAdd = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppTheme.accent)
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
}

// MARK: - Staff Row

struct StaffRowView: View {
    let staff: Staff
    let blockName: String

    var staffType: StaffType {
        StaffType(rawValue: staff.staffType) ?? .other
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(staffType.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: staffType.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(staffType.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(staff.fullName)
                        .font(.subheadline.bold())
                    if !staff.isActive {
                        Text("INACTIVE")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(AppTheme.danger)
                            .cornerRadius(4)
                    }
                }
                HStack(spacing: 6) {
                    Label(blockName, systemImage: "building.2")
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text("•")
                    Label(ShiftType(rawValue: staff.shift)?.displayName ?? staff.shift, systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            StatusBadge(
                text: staffType.displayName,
                color: staffType.color,
                small: true
            )
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(title)
                    .font(.caption.bold())
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? AppTheme.accent : Color(UIColor.tertiarySystemGroupedBackground))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}
