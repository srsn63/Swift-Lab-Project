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
        ShiftType(rawValue: staff.shift) ?? .morning
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(staffType.color.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: staffType.icon)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(staffType.color)
                    }

                    Text(staff.fullName)
                        .font(.title2.bold())

                    HStack(spacing: 8) {
                        StatusBadge(
                            text: staffType.displayName,
                            color: staffType.color
                        )
                        StatusBadge(
                            text: staff.isActive ? "Active" : "Inactive",
                            color: staff.isActive ? AppTheme.success : AppTheme.danger
                        )
                    }
                }
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemGroupedBackground))

                // Info sections
                VStack(spacing: 16) {
                    // Overview
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Overview", systemImage: "person.text.rectangle")
                            .font(.caption.bold())
                            .foregroundColor(AppTheme.accent)
                        Divider()
                        InfoRow(label: "Full Name", value: staff.fullName)
                        InfoRow(label: "Type", value: staffType.displayName)
                        InfoRow(label: "Phone", value: staff.phoneNumber.isEmpty ? "—" : staff.phoneNumber)
                        InfoRow(label: "Hire Date", value: staff.hireDate.formatted(date: .abbreviated, time: .omitted))
                        InfoRow(label: "Status", value: staff.isActive ? "Active" : "Inactive")
                    }
                    .padding(16)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(14)

                    // Assignment
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Assignment", systemImage: "building.2")
                            .font(.caption.bold())
                            .foregroundColor(AppTheme.accent)
                        Divider()
                        InfoRow(label: "Block", value: vm.blockName(for: staff.assignedBlockId))
                        InfoRow(label: "Shift", value: shiftType.displayName)
                    }
                    .padding(16)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(14)

                    // Notes
                    if !staff.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Notes", systemImage: "note.text")
                                .font(.caption.bold())
                                .foregroundColor(AppTheme.accent)
                            Divider()
                            Text(staff.notes)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                    }

                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            showEdit = true
                        } label: {
                            Label("Edit Profile", systemImage: "pencil")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppTheme.accent)
                                .cornerRadius(12)
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
                            .padding(.vertical, 12)
                            .background((staff.isActive ? AppTheme.danger : AppTheme.success).opacity(0.12))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(16)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
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
