import SwiftUI

struct MedicalRecordEditorView: View {
    @ObservedObject var vm: MedicalRecordsViewModel

    let existing: MedicalRecord?
    let currentUser: User
    let onSave: (MedicalRecord) async throws -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedInmateId = ""
    @State private var selectedDoctorId = ""
    @State private var conditionSummary = ""
    @State private var treatmentNotes = ""
    @State private var status: MedicalStatus = .inTreatment
    @State private var statusUpdatedAt = Date()
    @State private var errorMessage: String?

    private var isEditing: Bool { existing != nil }

    var body: some View {
        Form {
            Section {
                AppHeroHeader(
                    title: isEditing ? "Edit Medical Record" : "New Medical Record",
                    subtitle: "Choose the inmate, assign any active doctor in the prison, and record the latest medical status.",
                    icon: "cross.case.fill",
                    tint: .red,
                    badgeText: currentUser.role.capitalized
                )
            }
            .listRowBackground(Color.clear)

            Section {
                Menu {
                    ForEach(vm.availableInmates) { inmate in
                        Button("\(inmate.fullName) - Cell \(inmate.cellId)") {
                            selectedInmateId = inmate.id ?? ""
                        }
                    }
                } label: {
                    selectionRow(
                        icon: "person.crop.rectangle.stack.fill",
                        title: "Inmate",
                        value: selectedInmateLabel
                    )
                }

                if let inmateMessage = vm.inmateSelectionMessage(for: currentUser) {
                    AppMessageBanner(
                        text: inmateMessage,
                        tint: currentUser.assignedBlockId?.isEmpty == false ? AppTheme.warning : AppTheme.danger,
                        icon: currentUser.assignedBlockId?.isEmpty == false ? "person.crop.rectangle.stack" : "building.2"
                    )
                }

                Menu {
                    ForEach(vm.availableDoctors) { doctor in
                        Button(vm.doctorLabel(for: doctor)) {
                            selectedDoctorId = doctor.id ?? ""
                        }
                    }
                } label: {
                    selectionRow(
                        icon: "stethoscope",
                        title: "Assigned Doctor",
                        value: selectedDoctorLabel
                    )
                }

                if let doctorMessage = vm.doctorSelectionMessage(for: currentUser) {
                    AppMessageBanner(
                        text: doctorMessage,
                        tint: AppTheme.warning,
                        icon: "stethoscope.circle"
                    )
                }
            } header: {
                Label("Assignment", systemImage: "person.2.fill")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }
            .listRowBackground(AppTheme.surfaceElevated)

            Section {
                TextField("Condition / complaint", text: $conditionSummary, axis: .vertical)
                    .lineLimit(2...4)

                Picker("Medical Status", selection: $status) {
                    ForEach(MedicalStatus.allCases) { medicalStatus in
                        Text(medicalStatus.displayName).tag(medicalStatus)
                    }
                }

                DatePicker("Status Date", selection: $statusUpdatedAt, displayedComponents: .date)
            } header: {
                Label("Medical Record", systemImage: "cross.case.fill")
                    .font(.caption.bold())
                    .foregroundColor(.red)
            }
            .listRowBackground(AppTheme.surfaceElevated)

            Section {
                TextEditor(text: $treatmentNotes)
                    .frame(minHeight: 120)
            } header: {
                Label("Treatment Notes", systemImage: "note.text")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }
            .listRowBackground(AppTheme.surfaceElevated)

            if let vmError = vm.errorMessage {
                Section {
                    AppMessageBanner(text: vmError, tint: AppTheme.danger)
                }
                .listRowBackground(Color.clear)
            }

            if let err = errorMessage {
                Section {
                    AppMessageBanner(text: err, tint: AppTheme.danger)
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(isEditing ? "Edit Record" : "New Record")
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
                    .disabled(!canSave)
            }
        }
        .onAppear {
            loadExisting()
            if vm.availableInmates.isEmpty || vm.availableDoctors.isEmpty {
                Task {
                    if vm.blocks.isEmpty {
                        await vm.loadBlocks()
                    }
                    await vm.loadEditorData(for: currentUser)
                }
            }
        }
    }

    private var canSave: Bool {
        !selectedInmateId.isEmpty
            && !selectedDoctorId.isEmpty
            && !conditionSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var selectedInmateLabel: String {
        if let inmate = vm.availableInmates.first(where: { $0.id == selectedInmateId }) {
            return "\(inmate.fullName) - Cell \(inmate.cellId)"
        }

        if let existing, selectedInmateId == existing.inmateId {
            return existing.inmateName
        }

        return "Select inmate"
    }

    private var selectedDoctorLabel: String {
        if let doctor = vm.availableDoctors.first(where: { $0.id == selectedDoctorId }) {
            return vm.doctorLabel(for: doctor)
        }

        if let existing, selectedDoctorId == existing.doctorId {
            return existing.doctorName
        }

        return "Select doctor"
    }

    private func selectionRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.accent)
                .frame(width: 20)
            Text(title)
                .foregroundStyle(AppTheme.ink)
            Spacer()
            Text(value)
                .foregroundStyle(value.hasPrefix("Select") ? AppTheme.inkMuted : AppTheme.ink)
                .multilineTextAlignment(.trailing)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption)
                .foregroundStyle(AppTheme.inkMuted)
        }
    }

    private func loadExisting() {
        guard let existing else { return }

        selectedInmateId = existing.inmateId
        selectedDoctorId = existing.doctorId
        conditionSummary = existing.conditionSummary
        treatmentNotes = existing.treatmentNotes
        status = existing.medicalStatus
        statusUpdatedAt = existing.statusUpdatedAt
    }

    private func save() {
        errorMessage = nil

        guard let inmate = vm.availableInmates.first(where: { $0.id == selectedInmateId }) else {
            errorMessage = currentUser.assignedBlockId?.isEmpty == false
                ? "Select an inmate from your assigned block."
                : "You need a block assignment before creating a medical record."
            return
        }

        guard let doctor = vm.availableDoctors.first(where: { $0.id == selectedDoctorId }) else {
            errorMessage = "Select an active doctor from the available list."
            return
        }

        let trimmedSummary = conditionSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSummary.isEmpty else {
            errorMessage = "Enter a medical summary."
            return
        }

        Task {
            do {
                let now = Date()
                let record = MedicalRecord(
                    id: existing?.id,
                    inmateId: inmate.id ?? "",
                    inmateName: inmate.fullName,
                    blockId: inmate.blockId,
                    doctorId: doctor.id ?? "",
                    doctorName: doctor.fullName,
                    conditionSummary: trimmedSummary,
                    treatmentNotes: treatmentNotes.trimmingCharacters(in: .whitespacesAndNewlines),
                    status: status.rawValue,
                    createdByUserId: existing?.createdByUserId ?? currentUser.uid,
                    createdByName: existing?.createdByName ?? authorName,
                    createdAt: existing?.createdAt ?? now,
                    updatedAt: now,
                    statusUpdatedAt: statusUpdatedAt
                )

                try await onSave(record)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private var authorName: String {
        let trimmedName = currentUser.fullName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedName.isEmpty ? currentUser.email : trimmedName
    }
}
