import SwiftUI
import FirebaseFirestoreSwift

struct GuardEditorView: View {
    let user: User
    let onSave: (String, String, String, Date) async throws -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String = ""
    @State private var badgeNumber: String = ""
    @State private var assignedBlockId: String = ""
    @State private var dutyStartAt: Date = Date()

    @State private var blocks: [Block] = []
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                AppHeroHeader(
                    title: "Edit Guard",
                    subtitle: "Update guard identity, block assignment, and the repeating 8-hour duty cycle anchor.",
                    icon: "shield.fill",
                    tint: AppTheme.accent,
                    badgeText: user.role.capitalized
                )
            }
            .listRowBackground(Color.clear)

            Section {
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(AppTheme.accent)
                        .frame(width: 20)
                    Text(user.email)
                }

                HStack(spacing: 12) {
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundColor(AppTheme.accent)
                        .frame(width: 20)
                    Text(user.role.capitalized)
                }
            } header: {
                Label("Account", systemImage: "person.circle")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }
            .listRowBackground(AppTheme.surfaceElevated)

            Section {
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .foregroundColor(AppTheme.accent)
                        .frame(width: 20)
                    TextField("Full name", text: $fullName)
                }

                HStack(spacing: 12) {
                    Image(systemName: "number")
                        .foregroundColor(AppTheme.accent)
                        .frame(width: 20)
                    TextField("Badge number", text: $badgeNumber)
                }

                Menu {
                    Button("Unassigned") { assignedBlockId = "" }
                    ForEach(blocks) { block in
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

                DatePicker(selection: $dutyStartAt, displayedComponents: [.date, .hourAndMinute]) {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.badge.checkmark")
                            .foregroundColor(AppTheme.accent)
                            .frame(width: 20)
                        Text("First Duty Start")
                    }
                }

                AppMessageBanner(
                    text: "Each guard works 8 hours, rests 8 hours, and repeats from this first duty time.",
                    tint: AppTheme.accent,
                    icon: "clock.badge.checkmark"
                )

                if let err = errorMessage {
                    AppMessageBanner(text: err, tint: AppTheme.danger)
                }
            } header: {
                Label("Details", systemImage: "pencil")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }
            .listRowBackground(AppTheme.surfaceElevated)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppScreenBackground())
        .navigationTitle("Edit Guard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { save() }
                    .fontWeight(.semibold)
            }
        }
        .onAppear {
            fullName = user.fullName ?? ""
            badgeNumber = user.badgeNumber ?? ""
            assignedBlockId = user.assignedBlockId ?? ""
            dutyStartAt = user.dutyAnchorDate ?? ShiftDutySchedule.suggestedAnchorDate(for: user.shift)
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
                    assignedBlockId,
                    dutyStartAt
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
