import SwiftUI

struct GuardListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = GuardManagementViewModel()

    @State private var editing: User?
    @State private var actionError: String?

    @State private var showToast = false
    @State private var toastText = ""

    var body: some View {
        List {
            if let err = vm.errorMessage {
                Text(err).foregroundStyle(.red)
            }
            if let actionError {
                Text(actionError).foregroundStyle(.red)
            }

            ForEach(vm.guards) { g in
                VStack(alignment: .leading, spacing: 6) {
                    Text((g.fullName?.isEmpty == false) ? (g.fullName ?? "") : g.email)
                        .font(.headline)

                    Text("Badge: \(g.badgeNumber ?? "-") • Block: \(g.assignedBlockId ?? "-")")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        Button {
                            actionError = nil
                            editing = g
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .buttonStyle(.bordered)

                        Button(role: .destructive) {
                            actionError = nil
                            Task {
                                do {
                                    try await vm.deleteGuardDoc(uid: g.uid)
                                    toastText = "Guard profile deleted"
                                    withAnimation { showToast = true }
                                } catch {
                                    actionError = error.localizedDescription
                                }
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("Guards")
        .onAppear {
            // Extra safety: if not warden, do not even load
            guard authVM.currentUser?.role == "warden" else {
                vm.errorMessage = "Access denied (warden only)."
                return
            }
            vm.startListener()
        }
        .sheet(item: $editing) { guardUser in
            NavigationStack {
                GuardEditorView(user: guardUser) { fullName, badge, block in
                    do {
                        try await vm.updateGuard(uid: guardUser.uid,
                                                fullName: fullName,
                                                badgeNumber: badge,
                                                assignedBlock: block)
                        toastText = "Guard profile updated"
                        withAnimation { showToast = true }
                    } catch {
                        actionError = error.localizedDescription
                        throw error
                    }
                }
            }
        }
        .toast(isPresented: $showToast, text: toastText)
    }
}
