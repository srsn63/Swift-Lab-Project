import SwiftUI

struct InmateListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = InmateCRUDViewModel()

    @State private var searchText = ""
    @State private var showingAdd = false
    @State private var editingInmate: Inmate?

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
                Text(err).foregroundStyle(.red)
            }

            ForEach(filtered) { inmate in
                NavigationLink {
                    InmateDetailView(inmate: inmate)
                } label: {
                    VStack(alignment: .leading) {
                        Text(inmate.fullName)
                        Text("Block: \(inmate.blockId) • Cell: \(inmate.cellId) • \(inmate.securityLevel)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if !isGuard {
                        Button(role: .destructive) {
                            Task { try? await vm.delete(inmateId: inmate.id ?? "") }
                        } label: { Text("Delete") }

                        Button {
                            editingInmate = inmate
                        } label: { Text("Edit") }
                    }
                }
            }
        }
        .navigationTitle("Inmates")
        .searchable(text: $searchText)
        .toolbar {
            if !isGuard {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
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
    }
}
