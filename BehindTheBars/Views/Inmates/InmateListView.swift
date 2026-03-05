import SwiftUI

struct InmateListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = InmateCRUDViewModel()

    @State private var searchText = ""
    @State private var showingAdd = false
    @State private var editingInmate: Inmate?

    @State private var actionError: String?

    private var canWriteInmates: Bool {
        let role = authVM.currentUser?.role ?? ""
        return role == "warden" || role == "admin"
    }

    private var filtered: [Inmate] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return vm.inmates }
        return vm.inmates.filter { $0.fullName.lowercased().contains(q) || $0.cellId.lowercased().contains(q) }
    }

    var body: some View {
        List {
            if let err = vm.errorMessage { Text(err).foregroundStyle(.red) }
            if let actionError { Text(actionError).foregroundStyle(.red) }

            ForEach(filtered) { inmate in
                VStack(alignment: .leading, spacing: 6) {
                    Text(inmate.fullName).font(.headline)
                    Text("Block: \(inmate.blockId) • Cell: \(inmate.cellId) • \(inmate.securityLevel)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if canWriteInmates {
                        HStack(spacing: 10) {
                            Button { editingInmate = inmate } label: { Label("Edit", systemImage: "pencil") }
                                .buttonStyle(.bordered)

                            Button(role: .destructive) {
                                Task {
                                    do {
                                        guard let id = inmate.id else { return }
                                        try await vm.deleteInmateAndDecrementCell(inmateId: id, blockId: inmate.blockId, cellId: inmate.cellId)
                                    } catch {
                                        actionError = error.localizedDescription
                                    }
                                }
                            } label: { Label("Delete", systemImage: "trash") }
                                .buttonStyle(.bordered)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("Inmates")
        .searchable(text: $searchText)
        .toolbar {
            if canWriteInmates {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: { Label("Add", systemImage: "plus") }
                }
            }
        }
        .onAppear { vm.startListener() }
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
