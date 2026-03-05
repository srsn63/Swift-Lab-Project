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
                Section("Inmate") {
                    TextField("First name", text: $firstName)
                    TextField("Last name", text: $lastName)

                    Picker("Security level", selection: $securityLevel) {
                        ForEach(levels, id: \.self) { Text($0) }
                    }

                    Toggle("Solitary", isOn: $isSolitary)
                }

                Section("Sentence") {
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

                Section("Placement") {
                    Picker("Block", selection: $selectedBlockId) {
                        Text("Select").tag("")
                        ForEach(blocks) { b in
                            Text(b.name).tag(b.id ?? "")
                        }
                    }

                    Picker("Cell (available only)", selection: $selectedCellId) {
                        Text("Select").tag("")
                        ForEach(availableCells) { c in
                            Text("\(c.cellCode)  \(c.occupancy)/\(c.capacity)")
                                .tag(c.id ?? c.cellCode)
                        }
                    }
                    .disabled(selectedBlockId.isEmpty)
                }

                if let errorMessage {
                    Section("Error") {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Admit Inmate")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") { create() }
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
