import SwiftUI
import FirebaseFirestoreSwift

struct InmateAdmissionView: View {
    var onCreated: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = InmateCRUDViewModel()

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var securityLevel = "Low"
    @State private var isSolitary = false

    @State private var admissionDate = Date()
    @State private var sentenceMonths = 12

    @State private var selectedBlockId: String = ""
    @State private var selectedCellId: String = ""

    @State private var blocks: [Block] = []
    @State private var availableCells: [Cell] = []
    @State private var errorMessage: String?

    private let levels = ["Low", "Medium", "High"]

    var body: some View {
        NavigationStack {
            List {
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
                    Label("Inmate Details", systemImage: "person.text.rectangle")
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

                Section {
                    Picker("Block", selection: $selectedBlockId) {
                        Text("Select").tag("")
                        ForEach(blocks) { b in
                            Text(b.name).tag(b.id ?? "")
                        }
                    }

                    Picker("Cell", selection: $selectedCellId) {
                        Text("Select").tag("")
                        ForEach(availableCells) { c in
                            Text("\(c.cellCode)  (\(c.occupancy)/\(c.capacity))")
                                .tag(c.id ?? c.cellCode)
                        }
                    }
                    .disabled(selectedBlockId.isEmpty)
                } header: {
                    Label("Placement", systemImage: "building.2")
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
            .listStyle(.insetGrouped)
            .navigationTitle("Admit Inmate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") { create() }
                        .fontWeight(.semibold)
                        .disabled(isCreateDisabled)
                }
            }
            .task { await loadBlocks() }

            // iOS 16 signature: ONLY newValue
            .onChange(of: selectedBlockId) { newValue in
                selectedCellId = ""
                Task {
                    if newValue.isEmpty {
                        availableCells = []
                    } else {
                        await loadAvailableCells(blockId: newValue)
                    }
                }
            }
        }
    }

    private var isCreateDisabled: Bool {
        firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        selectedBlockId.isEmpty ||
        selectedCellId.isEmpty
    }

    private func create() {
        errorMessage = nil

        Task {
            do {
                if selectedBlockId.isEmpty {
                    errorMessage = "Select a block."
                    return
                }
                if selectedCellId.isEmpty {
                    errorMessage = "Select a cell."
                    return
                }

                let release = Calendar.current.date(byAdding: .month, value: sentenceMonths, to: admissionDate) ?? admissionDate

                let inmate = Inmate(
                    id: nil,
                    firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                    lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                    securityLevel: securityLevel,
                    blockId: selectedBlockId,
                    cellId: selectedCellId,
                    admissionDate: admissionDate,
                    sentenceMonths: sentenceMonths,
                    releaseDate: release,
                    isSolitary: isSolitary
                )

                try await vm.createInmateWithCellIncrement(
                    inmate: inmate,
                    blockId: selectedBlockId,
                    cellId: selectedCellId
                )

                onCreated()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func loadBlocks() async {
        do {
            let snap = try await FirebaseManager.shared.blocksRef.getDocuments()
            var list = snap.documents.compactMap { try? $0.data(as: Block.self) }
            list = list.filter { $0.id != nil }
            blocks = list.sorted { $0.name < $1.name }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadAvailableCells(blockId: String) async {
        do {
            let snap = try await FirebaseManager.shared.cellsRef(blockId: blockId).getDocuments()
            let all = snap.documents.compactMap { try? $0.data(as: Cell.self) }
            availableCells = all
                .filter { $0.occupancy < $0.capacity }
                .sorted { $0.cellCode < $1.cellCode }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
