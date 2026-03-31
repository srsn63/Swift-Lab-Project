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
    @StateObject private var blocksVM = BlocksDirectoryViewModel()

    @State private var editing: User?
    @State private var deleting: User?

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

            if vm.guards.isEmpty && vm.errorMessage == nil {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "shield")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("No guards found")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 40)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            ForEach(vm.guards) { g in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accent.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "shield.fill")
                                .foregroundColor(AppTheme.accent)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(displayName(for: g))
                                .font(.subheadline.bold())
                            if shouldShowEmail(for: g) {
                                Text(g.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        if let blockId = g.assignedBlockId, !blockId.isEmpty {
                            StatusBadge(text: getBlockName(id: blockId), color: AppTheme.accent, small: true)
                        } else {
                            StatusBadge(text: "Unassigned", color: .secondary, small: true)
                        }
                    }

                    if let badge = g.badgeNumber, !badge.isEmpty {
                        Label(badge, systemImage: "number")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 10) {
                        Button {
                            editing = g
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

                        if authVM.currentUser?.role == "admin" || authVM.currentUser?.role == "warden" {
                            Button {
                                deleting = g
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
                .padding(.vertical, 6)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Guards")
        .task {
            await blocksVM.load()
        }
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
        .alert("Delete Guard", isPresented: .constant(deleting != nil), presenting: deleting) { user in
            Button("Cancel", role: .cancel) {
                deleting = nil
            }
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await vm.deleteGuardDoc(uid: user.uid)
                    } catch {
                        vm.errorMessage = error.localizedDescription
                    }
                }
                deleting = nil
            }
        } message: { user in
            Text("Delete \(displayName(for: user))? This cannot be undone.")
        }
    }

    private func getBlockName(id: String) -> String {
        blocksVM.blocks.first(where: { $0.id == id })?.name ?? id
    }

    private func displayName(for user: User) -> String {
        let name = (user.fullName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? user.email : name
    }

    private func shouldShowEmail(for user: User) -> Bool {
        let name = (user.fullName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return !name.isEmpty
    }
}
