import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct AdminApprovalsView: View {
    @State private var pending: [User] = []
    @State private var error: String?

    var body: some View {
        ScrollView {
            if pending.isEmpty && error == nil {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundColor(AppTheme.success.opacity(0.5))
                    Text("No Pending Approvals")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("All accounts have been reviewed")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 100)
            } else {
                LazyVStack(spacing: 12) {
                    if let error {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppTheme.danger)
                            Text(error)
                                .foregroundStyle(AppTheme.danger)
                                .font(.footnote)
                        }
                        .padding()
                    }

                    ForEach(pending) { u in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.accent.opacity(0.12))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "person.fill")
                                        .foregroundColor(AppTheme.accent)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(u.email)
                                        .font(.subheadline.bold())
                                    HStack(spacing: 8) {
                                        StatusBadge(text: u.role.capitalized, color: .purple)
                                        StatusBadge(text: u.status.capitalized, color: .orange)
                                    }
                                }
                            }

                            HStack(spacing: 10) {
                                Button {
                                    Task { await setStatus(uid: u.uid, approved: true, status: "approved") }
                                } label: {
                                    Label("Approve", systemImage: "checkmark")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(AppTheme.success)
                                        .cornerRadius(10)
                                }

                                Button {
                                    Task { await setStatus(uid: u.uid, approved: false, status: "denied") }
                                } label: {
                                    Label("Deny", systemImage: "xmark")
                                        .font(.subheadline.bold())
                                        .foregroundColor(AppTheme.danger)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(AppTheme.danger.opacity(0.1))
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                    }
                }
                .padding(16)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
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
