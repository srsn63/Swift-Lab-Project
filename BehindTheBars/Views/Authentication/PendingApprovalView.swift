import SwiftUI

struct PendingApprovalView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Approval Required")
                .font(.title2).fontWeight(.semibold)

            Text("Your account is pending admin approval. You cannot access the system yet.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Button("Logout") {
                authVM.signOut()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
