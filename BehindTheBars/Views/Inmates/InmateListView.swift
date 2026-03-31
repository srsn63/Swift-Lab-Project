import SwiftUI

struct InmateListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = InmateCRUDViewModel()
    @StateObject private var blocksVM = BlocksDirectoryViewModel()

    @State private var searchText = ""
    @State private var showingAdd = false
    @State private var editingInmate: Inmate?
    @State private var deletingInmate: Inmate?

    private var isGuard: Bool { authVM.currentUser?.role == "guard" }
    private var guardBlockId: String { authVM.currentUser?.assignedBlockId ?? "" }

    private var filtered: [Inmate] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return vm.inmates }
        return vm.inmates.filter { $0.fullName.lowercased().contains(q) || $0.cellId.lowercased().contains(q) }
    }

    var body: some View {
        List {
            if let err = vm.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppTheme.danger)
                    Text(err)
                        .foregroundStyle(AppTheme.danger)
                        .font(.footnote)
                }
            }

            if filtered.isEmpty && vm.errorMessage == nil {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "person.crop.rectangle.stack")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text(searchText.isEmpty ? "No inmates found" : "No results for \"\(searchText)\"")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 40)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            ForEach(filtered) { inmate in
                VStack(alignment: .leading, spacing: 8) {
                    NavigationLink {
                        InmateDetailView(inmate: inmate)
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.securityColor(inmate.securityLevel).opacity(0.12))
                                    .frame(width: 44, height: 44)
                                Text(String(inmate.firstName.prefix(1)))
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(AppTheme.securityColor(inmate.securityLevel))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(inmate.fullName)
                                    .font(.subheadline.bold())
                                HStack(spacing: 6) {
                                    Label(getBlockName(id: inmate.blockId), systemImage: "building.2")
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    Text("•")
                                    Label(inmate.cellId, systemImage: "door.left.hand.closed")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }

                            Spacer()

                            StatusBadge(
                                text: inmate.securityLevel,
                                color: AppTheme.securityColor(inmate.securityLevel),
                                small: true
                            )
                        }
                        .padding(.vertical, 4)
                    }

                    if !isGuard {
                        HStack(spacing: 10) {
                            Button {
                                editingInmate = inmate
                            } label: {
                                Label("Edit", systemImage: "pencil")
                                    .font(.caption.bold())
                                    .foregroundColor(AppTheme.accent)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.accent.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)

                            Button {
                                deletingInmate = inmate
                            } label: {
                                Label("Delete", systemImage: "trash")
                                    .font(.caption.bold())
                                    .foregroundColor(AppTheme.danger)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.danger.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .task {
            await blocksVM.load()
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Inmates")
        .searchable(text: $searchText, prompt: "Search by name or cell")
        .toolbar {
            if !isGuard {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(AppTheme.accent)
                    }
                }
            }
        }
        .onAppear {
            if isGuard {
                if guardBlockId.isEmpty {
                    vm.inmates = []
                    vm.errorMessage = "You are not assigned to a block."
                } else {
                    vm.startListener(blockIdFilter: guardBlockId)
                }
            } else {
                vm.startListener()
            }
        }
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                InmateAdmissionView(onCreated: { })
            }
        }
        .sheet(item: $editingInmate) { inmate in
            NavigationStack {
                InmateEditorView(inmateId: inmate.id, existing: inmate) { updated in
                    guard let id = inmate.id else { return }
                    try await vm.update(inmateId: id, inmate: updated)
                }
            }
        }
        .alert("Delete Inmate", isPresented: .constant(deletingInmate != nil), presenting: deletingInmate) { inmate in
            Button("Cancel", role: .cancel) {
                deletingInmate = nil
            }
            Button("Delete", role: .destructive) {
                guard let id = inmate.id else { return }
                Task { try? await vm.delete(inmateId: id) }
                deletingInmate = nil
            }
        } message: { inmate in
            Text("Delete \(inmate.fullName)? This cannot be undone.")
        }
    }

    private func getBlockName(id: String) -> String {
        blocksVM.blocks.first(where: { $0.id == id })?.name ?? id
    }
}
