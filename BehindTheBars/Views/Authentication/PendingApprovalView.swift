import SwiftUI

struct PendingApprovalView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        ZStack {
            AppScreenBackground()

            VStack(spacing: 20) {
                AppHeroHeader(
                    title: "Approval Pending",
                    subtitle: "Your registration is under review. Access will unlock as soon as an administrator approves your account.",
                    icon: "hourglass",
                    tint: AppTheme.warning,
                    badgeText: "Pending"
                )

                AppSurfaceCard(tint: AppTheme.warning) {
                    VStack(spacing: 18) {
                        Text("Thanks for signing up. Until approval is complete, the system will remain locked for security.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AppTheme.inkMuted)

                        Button {
                            authVM.signOut()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.left")
                                Text("Sign Out")
                            }
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(AppTheme.danger)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
