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
                    AppHeroHeader(
                        title: "Admit Inmate",
                        subtitle: "Create a clean intake record with placement, sentence details, and the same card-based styling used across the app.",
                        icon: "person.crop.rectangle.stack.fill",
                        tint: AppTheme.accent,
                        badgeText: "New Intake"
                    )
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

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

                Section {
                    Picker("Block", selection: $selectedBlockId) {
                        Text("Select").tag("")
                        ForEach(blocks) { block in
                            Text(block.name).tag(block.id ?? "")
                        }
                    }

                    Picker("Cell", selection: $selectedCellId) {
                        Text("Select").tag("")
                        ForEach(availableCells) { cell in
                            Text("\(cell.cellCode) (\(cell.occupancy)/\(cell.capacity))")
                                .tag(cell.id ?? cell.cellCode)
                        }
                    }
                    .disabled(selectedBlockId.isEmpty)

                    if !selectedBlockId.isEmpty {
                        AppMessageBanner(
                            text: selectedCellId.isEmpty
                                ? "Choose an available cell in \(selectedBlockName)."
                                : "Placement set to \(selectedBlockName), cell \(selectedCellId).",
                            tint: AppTheme.accent,
                            icon: "building.2"
                        )
                    }
                } header: {
                    Label("Placement", systemImage: "building.2")
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
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppScreenBackground())
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

    private var selectedBlockName: String {
        blocks.first(where: { $0.id == selectedBlockId })?.name ?? selectedBlockId
    }

    private var releaseDate: Date {
        Calendar.current.date(byAdding: .month, value: sentenceMonths, to: admissionDate) ?? admissionDate
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

                let inmate = Inmate(
                    id: nil,
                    firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                    lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                    securityLevel: securityLevel,
                    blockId: selectedBlockId,
                    cellId: selectedCellId,
                    admissionDate: admissionDate,
                    sentenceMonths: sentenceMonths,
                    releaseDate: releaseDate,
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
