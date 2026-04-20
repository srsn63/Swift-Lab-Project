import SwiftUI
import FirebaseFirestore

struct StaffEditorView: View {
    @ObservedObject var vm: StaffViewModel
    let existing: Staff?
    let onSave: (Staff) async throws -> Void

    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var staffType: StaffType = .other
    @State private var phoneNumber = ""
    @State private var assignedBlockId = ""
    @State private var selectedShift: ShiftType = .morning
    @State private var dutyStartAt = Date()
    @State private var hireDate = Date()
    @State private var isActive = true
    @State private var notes = ""
    @State private var errorMessage: String?

    private var isEditing: Bool { existing != nil }

    var body: some View {
        Form {
            Section {
                AppHeroHeader(
                    title: isEditing ? "Edit Staff Member" : "Add Staff Member",
                    subtitle: "Create polished staff profiles with explicit shift groups, duty anchors, and prison-wide block scope when needed.",
                    icon: staffType.icon,
                    tint: staffType.color,
                    badgeText: staffType.displayName
                )
            }
            .listRowBackground(Color.clear)

            Section {
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .foregroundColor(AppTheme.accent)
                        .frame(width: 20)
                    TextField("Full name", text: $fullName)
                }

                HStack(spacing: 12) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(AppTheme.accent)
                        .frame(width: 20)
                    TextField("Phone number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }

                Menu {
                    ForEach(StaffType.allCases) { type in
                        Button {
                            staffType = type
                        } label: {
                            Label(type.displayName, systemImage: type.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "tag.fill")
                            .foregroundColor(AppTheme.accent)
                            .frame(width: 20)
                        Text("Staff Type")
                        Spacer()
                        Text(staffType.displayName)
                            .foregroundStyle(AppTheme.inkMuted)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(AppTheme.inkMuted)
                    }
                }

                DatePicker(selection: $hireDate, displayedComponents: .date) {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .foregroundColor(AppTheme.accent)
                            .frame(width: 20)
                        Text("Hire Date")
                    }
                }
            } header: {
                Label("Basic Info", systemImage: "person.text.rectangle")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }
            .listRowBackground(AppTheme.surfaceElevated)

            Section {
                Menu {
                    Button("Unassigned") { assignedBlockId = "" }
                    Button("All Blocks") { assignedBlockId = BlockAssignment.allBlocksId }
                    ForEach(vm.blocks) { block in
                        Button(block.name) { assignedBlockId = block.id ?? "" }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "building.2")
                            .foregroundColor(AppTheme.accent)
                            .frame(width: 20)
                        Text("Assigned Block")
                        Spacer()
                        Text(currentBlockName)
                            .foregroundStyle(AppTheme.inkMuted)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(AppTheme.inkMuted)
                    }
                }

                Menu {
                    ForEach(ShiftType.allCases) { shift in
                        Button {
                            selectedShift = shift
                        } label: {
                            Label(shift.displayName, systemImage: shift.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: selectedShift.icon)
                            .foregroundColor(AppTheme.accent)
                            .frame(width: 20)
                        Text("Shift Group")
                        Spacer()
                        Text(selectedShift.displayName)
                            .foregroundStyle(AppTheme.inkMuted)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(AppTheme.inkMuted)
                    }
                }

                DatePicker(selection: $dutyStartAt, displayedComponents: .date) {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.badge.checkmark")
                            .foregroundColor(AppTheme.accent)
                            .frame(width: 20)
                        Text("First Duty Date")
                    }
                }

                HStack(spacing: 12) {
                    Image(systemName: "clock")
                        .foregroundColor(AppTheme.accent)
                        .frame(width: 20)
                    Text("First Duty Start")
                    Spacer()
                    Text(snappedDutyStartAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(AppTheme.inkMuted)
                }

                AppMessageBanner(
                    text: "The shift group locks the anchor time to 06:00, 14:00, or 22:00 on the selected date for the repeating 8-hour duty cycle.",
                    tint: AppTheme.accent,
                    icon: "clock.badge.checkmark"
                )
            } header: {
                Label("Assignment", systemImage: "mappin.and.ellipse")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }
            .listRowBackground(AppTheme.surfaceElevated)

            Section {
                Toggle(isOn: $isActive) {
                    HStack(spacing: 12) {
                        Image(systemName: isActive ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isActive ? AppTheme.success : AppTheme.danger)
                            .frame(width: 20)
                        Text("Active")
                    }
                }
            } header: {
                Label("Status", systemImage: "power")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }
            .listRowBackground(AppTheme.surfaceElevated)

            Section {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            } header: {
                Label("Notes", systemImage: "note.text")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }
            .listRowBackground(AppTheme.surfaceElevated)

            if let err = errorMessage {
                Section {
                    AppMessageBanner(text: err, tint: AppTheme.danger)
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(isEditing ? "Edit Staff" : "Add Staff")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(AppScreenBackground())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { save() }
                    .fontWeight(.semibold)
                    .disabled(fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            loadExisting()
            if vm.blocks.isEmpty {
                Task { await vm.loadBlocks() }
            }
        }
        .onChange(of: selectedShift) { _ in
            let snapped = snappedDutyStartAt
            if dutyStartAt != snapped {
                dutyStartAt = snapped
            }
        }
        .onChange(of: dutyStartAt) { _ in
            let snapped = snappedDutyStartAt
            if dutyStartAt != snapped {
                dutyStartAt = snapped
            }
        }
    }

    private var currentBlockName: String {
        BlockAssignment.displayName(for: assignedBlockId, blocks: vm.blocks)
    }

    private var snappedDutyStartAt: Date {
        ShiftDutySchedule.anchorDate(for: selectedShift, on: dutyStartAt)
    }

    private func loadExisting() {
        if let existing {
            fullName = existing.fullName
            staffType = StaffType(rawValue: existing.staffType) ?? .other
            phoneNumber = existing.phoneNumber
            assignedBlockId = BlockAssignment.normalized(existing.assignedBlockId)
            selectedShift = ShiftType(rawValue: existing.resolvedShift) ?? .morning
            dutyStartAt = ShiftDutySchedule.anchorDate(
                for: selectedShift,
                on: existing.dutyAnchorDate ?? ShiftDutySchedule.suggestedAnchorDate(for: existing.shift)
            )
            hireDate = existing.hireDate
            isActive = existing.isActive
            notes = existing.notes
        } else {
            selectedShift = .morning
            dutyStartAt = ShiftDutySchedule.anchorDate(for: selectedShift, on: dutyStartAt)
        }
    }

    private func save() {
        errorMessage = nil
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Full name is required."
            return
        }

        Task {
            do {
                let now = Date()
                let staff = Staff(
                    id: existing?.id,
                    fullName: trimmedName,
                    staffType: staffType.rawValue,
                    phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                    assignedBlockId: BlockAssignment.normalized(assignedBlockId),
                    shift: selectedShift.rawValue,
                    hireDate: hireDate,
                    isActive: isActive,
                    notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                    createdBy: existing?.createdBy ?? (authVM.currentUser?.uid ?? ""),
                    createdAt: existing?.createdAt ?? now,
                    updatedAt: now,
                    dutyStartAt: snappedDutyStartAt
                )
                try await onSave(staff)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
