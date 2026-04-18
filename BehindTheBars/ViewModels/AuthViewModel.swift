import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?

    private let db = Firestore.firestore()
    private var currentUserListener: ListenerRegistration?

    deinit {
        currentUserListener?.remove()
    }

    init() {
        self.userSession = Auth.auth().currentUser
        if let uid = self.userSession?.uid {
            startCurrentUserListener(for: uid)
        }
        Task { await fetchCurrentUser() }
    }

    func signIn(email: String, password: String) async throws {
        let email = normalize(email)
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        self.userSession = result.user
        startCurrentUserListener(for: result.user.uid)
        await fetchCurrentUser()
    }

    func createUser(email: String, password: String) async throws {
        let email = normalize(email)

        guard let role = roleFromEmail(email) else {
            throw AuthVMError.invalidEmailDomain
        }

        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        self.userSession = result.user

        let uid = result.user.uid
        let userDoc = User(
            id: uid,
            uid: uid,
            email: email,
            role: role,
            createdAt: Timestamp(date: Date()),
            approved: false,
            status: "pending",
            fullName: nil,
            badgeNumber: nil,
            assignedBlockId: nil,
            shift: nil,
            dutyStartAt: nil
        )

        try db.collection("users").document(uid).setData(from: userDoc, merge: false)
        self.currentUser = userDoc
        startCurrentUserListener(for: uid)
    }

    func signOut() {
        try? Auth.auth().signOut()
        currentUserListener?.remove()
        currentUserListener = nil
        self.userSession = nil
        self.currentUser = nil
    }

    func fetchCurrentUser() async {
        guard let fbUser = Auth.auth().currentUser else {
            currentUserListener?.remove()
            currentUserListener = nil
            self.currentUser = nil
            return
        }
        let uid = fbUser.uid

        do {
            let snap = try await db.collection("users").document(uid).getDocument()
            if snap.exists {
                self.currentUser = try snap.data(as: User.self)
                startCurrentUserListener(for: uid)
            } else {
                // If missing doc, do not auto-create (approval system relies on explicit signup)
                self.currentUser = nil
            }
        } catch {
            self.currentUser = nil
        }
    }

    var canEnterApp: Bool {
        guard let u = currentUser else { return false }
        if u.role == "admin" { return true }
        return u.approved == true && u.status == "approved"
    }

    private func normalize(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func roleFromEmail(_ email: String) -> String? {
        if email == "admin@gmail.com" { return "admin" } 
        if email.hasSuffix("@guard.com") { return "guard" }
        if email.hasSuffix("@warden.com") { return "warden" }
        return nil
    }

    private func startCurrentUserListener(for uid: String) {
        currentUserListener?.remove()
        currentUserListener = db.collection("users").document(uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }

                guard let snapshot else {
                    self.currentUser = nil
                    return
                }

                if snapshot.exists {
                    self.currentUser = try? snapshot.data(as: User.self)
                } else {
                    self.currentUser = nil
                }
            }
    }

    enum AuthVMError: LocalizedError {
        case invalidEmailDomain

        var errorDescription: String? {
            "Email must end with @guard.com or @warden.com."
        }
    }
}
