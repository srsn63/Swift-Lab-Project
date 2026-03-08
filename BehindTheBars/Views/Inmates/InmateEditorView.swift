import SwiftUI

struct InmateEditorView: View {
    let inmateId: String?
    let existing: Inmate?
    let onSave: (Inmate) async throws -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var securityLevel = "Low"
    @State private var isSolitary = false

    @State private var blockId = ""
    @State private var cellId = ""
    @State private var admissionDate = Date()
    @State private var sentenceMonths = 12

    @State private var errorMessage: String?

    private let levels = ["Low", "Medium", "High"]

    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .foregroundColor(AppTheme.accent)
                        .frame(width: 20)
                    TextField("First name", text: $firstName)
                }
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .foregroundColor(AppTheme.accent)
                        .frame(width: 20)
                    TextField("Last name", text: $lastName)
                }
            } header: {
                Label("Identity", systemImage: "person.text.rectangle")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }

            Section {
                Picker("Security level", selection: $securityLevel) {
                    ForEach(levels, id: \.self) { level in
                        HStack {
                            Circle()
                                .fill(AppTheme.securityColor(level))
                                .frame(width: 8, height: 8)
                            Text(level)
                        }
                        .tag(level)
                    }
                }
                Toggle(isOn: $isSolitary) {
                    Label("Solitary Confinement", systemImage: "lock.fill")
                }
            } header: {
                Label("Security", systemImage: "shield.lefthalf.filled")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }

            Section {
                HStack {
                    Label("Block", systemImage: "building.2")
                    Spacer()
                    Text(blockId.isEmpty ? "\u{2014}" : blockId)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Label("Cell", systemImage: "door.left.hand.closed")
                    Spacer()
                    Text(cellId.isEmpty ? "\u{2014}" : cellId)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label("Placement", systemImage: "mappin.and.ellipse")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }

            Section {
                DatePicker("Admission date", selection: $admissionDate, displayedComponents: .date)
                Stepper("Sentence: \(sentenceMonths) months", value: $sentenceMonths, in: 1...600)

                let release = Calendar.current.date(byAdding: .month, value: sentenceMonths, to: admissionDate) ?? admissionDate
                HStack {
                    Text("Release date")
                    Spacer()
                    Text(release.formatted(date: .abbreviated, time: .omitted))
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label("Sentence", systemImage: "calendar")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }

            if let errorMessage {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppTheme.danger)
                        Text(errorMessage)
                            .foregroundStyle(AppTheme.danger)
                            .font(.footnote)
                    }
                }
            }
        }
        .navigationTitle(inmateId == nil ? "Add Inmate" : "Edit Inmate")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { save() }
                    .fontWeight(.semibold)
                    .disabled(firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              blockId.isEmpty ||
                              cellId.isEmpty)
            }
        }
        .onAppear { loadExisting() }
    }

    private func loadExisting() {
        if let existing {
            firstName = existing.firstName
            lastName = existing.lastName
            securityLevel = existing.securityLevel
            isSolitary = existing.isSolitary

            blockId = existing.blockId
            cellId = existing.cellId
            admissionDate = existing.admissionDate
            sentenceMonths = existing.sentenceMonths
        } else {
            blockId = ""
            cellId = ""
        }
    }

    private func save() {
        errorMessage = nil

        Task {
            do {
                let release = Calendar.current.date(byAdding: .month, value: sentenceMonths, to: admissionDate) ?? admissionDate

                let inmate = Inmate(
                    id: existing?.id,
                    firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                    lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                    securityLevel: securityLevel,
                    blockId: blockId,
                    cellId: cellId,
                    admissionDate: admissionDate,
                    sentenceMonths: sentenceMonths,
                    releaseDate: release,
                    isSolitary: isSolitary
                )

                try await onSave(inmate)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
