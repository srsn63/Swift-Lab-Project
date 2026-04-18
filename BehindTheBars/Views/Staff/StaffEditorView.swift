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
    @State private var dutyStartAt = Date()
    @State private var hireDate = Date()
    @State private var isActive = true
    @State private var notes = ""
    @State private var errorMessage: String?

    private var isEditing: Bool { existing != nil }

    var body: some View {
        Form {
            // Basic Info
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

                // Staff Type picker
                Picker(selection: $staffType) {
                    ForEach(StaffType.allCases) { type in
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundColor(type.color)
                            Text(type.displayName)
                        }
                        .tag(type)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "tag.fill")
                            .foregroundColor(AppTheme.accent)
                            .frame(width: 20)
                        Text("Staff Type")
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

            // Assignment
            Section {
                // Block picker
                Menu {
                    Button("Unassigned") { assignedBlockId = "" }
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
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                DatePicker(selection: $dutyStartAt, displayedComponents: [.date, .hourAndMinute]) {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.badge.checkmark")
                            .foregroundColor(AppTheme.accent)
                            .frame(width: 20)
                        Text("First Duty Start")
                    }
                }

                HStack(spacing: 12) {
                    Image(systemName: derivedShift.icon)
                        .foregroundColor(AppTheme.accent)
                        .frame(width: 20)
                    Text("Shift Group")
                    Spacer()
                    Text(derivedShift.displayName)
                        .foregroundStyle(.secondary)
                }

                Text("This start time drives the repeating 8-hour duty and 8-hour rest cycle in real time.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Assignment", systemImage: "mappin.and.ellipse")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }

            // Status
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

            // Notes
            Section {
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
            } header: {
                Label("Notes", systemImage: "note.text")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }

            if let err = errorMessage {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppTheme.danger)
                        Text(err)
                            .foregroundStyle(AppTheme.danger)
                            .font(.footnote)
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Staff" : "Add Staff")
        .navigationBarTitleDisplayMode(.inline)
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
    }

    private var currentBlockName: String {
        if assignedBlockId.isEmpty { return "Unassigned" }
        return vm.blocks.first(where: { $0.id == assignedBlockId })?.name ?? "Unknown"
    }

    private var derivedShift: ShiftType {
        ShiftType(rawValue: ShiftDutySchedule.initialShiftName(for: dutyStartAt)) ?? .morning
    }

    private func loadExisting() {
        if let existing {
            fullName = existing.fullName
            staffType = StaffType(rawValue: existing.staffType) ?? .other
            phoneNumber = existing.phoneNumber
            assignedBlockId = existing.assignedBlockId
            dutyStartAt = existing.dutyAnchorDate ?? ShiftDutySchedule.suggestedAnchorDate(for: existing.shift)
            hireDate = existing.hireDate
            isActive = existing.isActive
            notes = existing.notes
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
                    assignedBlockId: assignedBlockId,
                    shift: derivedShift.rawValue,
                    hireDate: hireDate,
                    isActive: isActive,
                    notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                    createdBy: existing?.createdBy ?? (authVM.currentUser?.uid ?? ""),
                    createdAt: existing?.createdAt ?? now,
                    updatedAt: now,
                    dutyStartAt: dutyStartAt
                )
                try await onSave(staff)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
