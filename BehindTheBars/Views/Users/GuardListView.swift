import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class GuardListViewModel: ObservableObject {
    @Published var guards: [User] = []
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?

    deinit { listener?.remove() }

    func startListener() {
        listener?.remove()
        errorMessage = nil

        listener = FirebaseManager.shared.usersRef
            .whereField("role", isEqualTo: "guard")
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let err {
                    self.errorMessage = err.localizedDescription
                    return
                }
                let list = snap?.documents.compactMap { try? $0.data(as: User.self) } ?? []
                self.guards = list.sorted { $0.email < $1.email }
            }
    }

    func stopListener() {
        listener?.remove()
        listener = nil
    }

    func deleteGuardDoc(uid: String) async throws {
        try await FirebaseManager.shared.usersRef.document(uid).delete()
    }

    func updateGuard(uid: String, fullName: String, badge: String, blockId: String) async throws {
        try await FirebaseManager.shared.usersRef.document(uid).updateData([
            "fullName": fullName,
            "badgeNumber": badge,
            "assignedBlockId": blockId
        ])
    }
}

struct GuardListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = GuardListViewModel()

    @State private var editing: User?

    var body: some View {
        List {
            if let err = vm.errorMessage {
                Text(err).foregroundStyle(.red)
            }

            ForEach(vm.guards) { g in
                VStack(alignment: .leading, spacing: 6) {
                    Text(g.email).font(.headline)

                    Text("Badge: \(g.badgeNumber ?? "-") • BlockId: \(g.assignedBlockId ?? "-")")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Button {
                            editing = g
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .buttonStyle(.bordered)

                        if authVM.currentUser?.role == "admin" {
                            Button(role: .destructive) {
                                Task {
                                    do {
                                        try await vm.deleteGuardDoc(uid: g.uid)
                                    } catch {
                                        vm.errorMessage = error.localizedDescription
                                    }
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.top, 6)
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("Guards")
        .onAppear { vm.startListener() }
        .onDisappear { vm.stopListener() }
        .sheet(item: $editing) { guardUser in
            NavigationStack {
                GuardEditorView(user: guardUser) { fullName, badge, blockId in
                    try await vm.updateGuard(
                        uid: guardUser.uid,
                        fullName: fullName,
                        badge: badge,
                        blockId: blockId
                    )
                }
            }
        }
    }
}
