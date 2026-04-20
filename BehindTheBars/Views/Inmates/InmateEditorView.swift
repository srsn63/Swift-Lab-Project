import SwiftUI

struct InmateEditorView: View {
    let inmateId: String?
    let existing: Inmate?
    let onSave: (Inmate) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var blocksVM = BlocksDirectoryViewModel()

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
                AppHeroHeader(
                    title: inmateId == nil ? "Add Inmate" : "Edit Inmate",
                    subtitle: "Keep inmate identity and sentence records aligned with the app's updated card-based design.",
                    icon: "person.text.rectangle",
                    tint: AppTheme.accent,
                    badgeText: securityLevel.uppercased()
                )
            }
            .listRowBackground(Color.clear)

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
            .listRowBackground(AppTheme.surfaceElevated)

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
            .listRowBackground(AppTheme.surfaceElevated)

            Section {
                HStack {
                    Label("Block", systemImage: "building.2")
                    Spacer()
                    Text(blockId.isEmpty ? "---" : blockLabel)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Label("Cell", systemImage: "door.left.hand.closed")
                    Spacer()
                    Text(cellId.isEmpty ? "---" : cellId)
                        .foregroundStyle(.secondary)
                }

                AppMessageBanner(
                    text: "Placement is preserved here so edits do not accidentally move the inmate out of the assigned block or cell.",
                    tint: AppTheme.accent,
                    icon: "building.2"
                )
            } header: {
                Label("Placement", systemImage: "mappin.and.ellipse")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }
            .listRowBackground(AppTheme.surfaceElevated)

            Section {
                DatePicker("Admission date", selection: $admissionDate, displayedComponents: .date)
                Stepper("Sentence: \(sentenceMonths) months", value: $sentenceMonths, in: 1...600)

                HStack {
                    Text("Release date")
                    Spacer()
                    Text(releaseDate.formatted(date: .abbreviated, time: .omitted))
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label("Sentence", systemImage: "calendar")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }
            .listRowBackground(AppTheme.surfaceElevated)

            if let errorMessage {
                Section {
                    AppMessageBanner(text: errorMessage, tint: AppTheme.danger)
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(inmateId == nil ? "Add Inmate" : "Edit Inmate")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(AppScreenBackground())
        .task {
            await blocksVM.load()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { save() }
                    .fontWeight(.semibold)
                    .disabled(
                        firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        blockId.isEmpty ||
                        cellId.isEmpty
                    )
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

    private var blockLabel: String {
        BlockAssignment.displayName(for: blockId, blocks: blocksVM.blocks)
    }

    private var releaseDate: Date {
        Calendar.current.date(byAdding: .month, value: sentenceMonths, to: admissionDate) ?? admissionDate
    }

    private func save() {
        errorMessage = nil

        Task {
            do {
                let inmate = Inmate(
                    id: existing?.id,
                    firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                    lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                    securityLevel: securityLevel,
                    blockId: blockId,
                    cellId: cellId,
                    admissionDate: admissionDate,
                    sentenceMonths: sentenceMonths,
                    releaseDate: releaseDate,
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
