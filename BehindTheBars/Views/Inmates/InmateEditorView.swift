import SwiftUI

struct InmateEditorView: View {
    let inmateId: String?          // nil = create, non-nil = edit
    let existing: Inmate?
    let onSave: (Inmate) async throws -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var securityLevel = "Low"
    @State private var isSolitary = false

    // New model fields
    @State private var blockId = ""
    @State private var cellId = ""
    @State private var admissionDate = Date()
    @State private var sentenceMonths = 12

    @State private var errorMessage: String?

    private let levels = ["Low", "Medium", "High"]

    var body: some View {
        Form {
            Section(header: Text("Identity")) {
                TextField("First name", text: $firstName)
                TextField("Last name", text: $lastName)
            }

            Section(header: Text("Security")) {
                Picker("Security level", selection: $securityLevel) {
                    ForEach(levels, id: \.self) { Text($0) }
                }
                Toggle("Solitary", isOn: $isSolitary)
            }

            Section(header: Text("Placement")) {
                // Keep these read-only in edit mode to avoid breaking cell occupancy logic.
                HStack {
                    Text("Block")
                    Spacer()
                    Text(blockId.isEmpty ? "--" : blockId)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Cell")
                    Spacer()
                    Text(cellId.isEmpty ? "--" : cellId)
                        .foregroundStyle(.secondary)
                }
            }

            Section(header: Text("Sentence")) {
                DatePicker("Admission date", selection: $admissionDate, displayedComponents: .date)
                Stepper("Sentence months: \(sentenceMonths)", value: $sentenceMonths, in: 1...600)

                let release = Calendar.current.date(byAdding: .month, value: sentenceMonths, to: admissionDate) ?? admissionDate
                HStack {
                    Text("Release date")
                    Spacer()
                    Text(release.formatted(date: .abbreviated, time: .omitted))
                        .foregroundStyle(.secondary)
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(inmateId == nil ? "Add Inmate" : "Edit Inmate")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { save() }
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
            // Creating from this screen is NOT recommended anymore.
            // Admission should happen via InmateAdmissionView (block/cell capacity enforcement).
            // Leave blockId/cellId empty to force using the admission screen.
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
