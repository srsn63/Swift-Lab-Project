import SwiftUI
import FirebaseFirestoreSwift

struct GuardEditorView: View {
    let user: User
    let onSave: (String, String, String) async throws -> Void // fullName, badgeNumber, assignedBlockId

    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String = ""
    @State private var badgeNumber: String = ""
    @State private var assignedBlockId: String = ""   // MUST be blocks/{blockId} document id

    @State private var blocks: [Block] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("Account") {
                Text(user.email)
                Text(user.role)
            }

            Section("Editable") {
                TextField("Full name", text: $fullName)
                TextField("Badge number", text: $badgeNumber)

                Menu {
                    Button("Unassigned") { assignedBlockId = "" }
                    ForEach(blocks) { b in
                        Button(b.name) { assignedBlockId = b.id ?? "" }
                    }
                } label: {
                    HStack {
                        Text("Assigned block")
                        Spacer()
                        Text(currentBlockName).foregroundStyle(.secondary)
                        Image(systemName: "chevron.down").foregroundStyle(.secondary)
                    }
                }

                if let err = errorMessage {
                    Text(err).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Edit Guard")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { save() }
            }
        }
        .onAppear {
            fullName = user.fullName ?? ""
            badgeNumber = user.badgeNumber ?? ""
            assignedBlockId = user.assignedBlockId ?? ""
            Task { await loadBlocks() }
        }
    }

    private var currentBlockName: String {
        if assignedBlockId.isEmpty { return "Unassigned" }
        return blocks.first(where: { $0.id == assignedBlockId })?.name ?? "Unknown"
    }

    private func loadBlocks() async {
        do {
            let snap = try await FirebaseManager.shared.blocksRef.getDocuments()
            var list = snap.documents.compactMap { try? $0.data(as: Block.self) }
            list = list.filter { $0.id != nil }.sorted { $0.name < $1.name }
            blocks = list
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save() {
        errorMessage = nil
        Task {
            do {
                try await onSave(
                    fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                    badgeNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                    assignedBlockId
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
