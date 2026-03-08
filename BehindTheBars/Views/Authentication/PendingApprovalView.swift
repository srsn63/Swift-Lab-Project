import SwiftUI

struct PendingApprovalView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        ZStack {
            AppTheme.headerGradient.ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Image(systemName: "hourglass")
                        .font(.system(size: 44))
                        .foregroundColor(.white.opacity(0.85))
                }

                VStack(spacing: 10) {
                    Text("Approval Pending")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)

                    Text("Your account is under review.\nYou\u{2019}ll be able to access the system once an administrator approves your registration.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.65))
                        .font(.subheadline)
                        .padding(.horizontal, 32)
                }

                Button {
                    authVM.signOut()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left")
                        Text("Sign Out")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(.white.opacity(0.15))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.25), lineWidth: 1)
                    )
                }
                .padding(.top, 8)
            }
        }
    }
}
