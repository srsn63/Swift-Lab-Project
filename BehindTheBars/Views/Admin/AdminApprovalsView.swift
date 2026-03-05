import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct AdminApprovalsView: View {
    @State private var pending: [User] = []
    @State private var error: String?

    var body: some View {
        List {
            if let error { Text(error).foregroundStyle(.red) }

            ForEach(pending) { u in
                VStack(alignment: .leading, spacing: 6) {
                    Text(u.email).font(.headline)
                    Text("Role: \(u.role) • Status: \(u.status)")
                        .font(.footnote).foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        Button("Approve") {
                            Task { await setStatus(uid: u.uid, approved: true, status: "approved") }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Deny") {
                            Task { await setStatus(uid: u.uid, approved: false, status: "denied") }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("Approvals")
        .task { await loadPending() }
    }

    private func loadPending() async {
        do {
            let snap = try await FirebaseManager.shared.usersRef
                .whereField("status", isEqualTo: "pending")
                .getDocuments()
            pending = snap.documents.compactMap { try? $0.data(as: User.self) }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func setStatus(uid: String, approved: Bool, status: String) async {
        do {
            try await FirebaseManager.shared.usersRef.document(uid).updateData([
                "approved": approved,
                "status": status
            ])
            await loadPending()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
