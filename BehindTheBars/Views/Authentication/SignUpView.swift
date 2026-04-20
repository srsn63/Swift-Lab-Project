import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?

    private var normalizedEmail: String { email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

    private var derivedRole: String? {
        if normalizedEmail.hasSuffix("@guard.com") { return "guard" }
        if normalizedEmail.hasSuffix("@warden.com") { return "warden" }
        return nil
    }

    private var canSubmit: Bool {
        guard derivedRole != nil else { return false }
        guard password.count >= 6 else { return false }
        guard password == confirmPassword else { return false }
        return normalizedEmail.contains("@")
    }

    var body: some View {
        ZStack {
            AppScreenBackground()

            ScrollView {
                VStack(spacing: 18) {
                    AppHeroHeader(
                        title: "Create Account",
                        subtitle: "Request secure access as a guard or warden using your approved institutional email.",
                        icon: "person.badge.plus",
                        tint: AppTheme.accent,
                        badgeText: "Request Access"
                    )

                    AppSurfaceCard(tint: AppTheme.accent, padding: 24) {
                        VStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.caption.bold())
                                    .foregroundColor(.secondary)
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(AppTheme.accent)
                                .frame(width: 20)
                                TextField("name@guard.com or name@warden.com", text: $email)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                            }
                            .padding(14)
                            .background(Color(UIColor.tertiarySystemFill))
                            .cornerRadius(12)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(AppTheme.accent)
                                    .frame(width: 20)
                                SecureField("Minimum 6 characters", text: $password)
                            }
                            .padding(14)
                            .background(Color(UIColor.tertiarySystemFill))
                            .cornerRadius(12)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Confirm Password")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            HStack(spacing: 12) {
                                Image(systemName: "lock.rotation")
                                    .foregroundColor(AppTheme.accent)
                                    .frame(width: 20)
                                SecureField("Re-enter password", text: $confirmPassword)
                            }
                            .padding(14)
                            .background(Color(UIColor.tertiarySystemFill))
                            .cornerRadius(12)
                        }

                        // Role indicator
                        HStack {
                            Image(systemName: "shield.lefthalf.filled")
                                .foregroundColor(derivedRole != nil ? AppTheme.accent : .secondary)
                            Text("Role:")
                                .foregroundStyle(.secondary)
                            Text(derivedRole?.capitalized ?? "Use @guard.com or @warden.com")
                                .fontWeight(.semibold)
                                .foregroundColor(derivedRole != nil ? AppTheme.accent : AppTheme.danger)
                        }
                        .font(.subheadline)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            (derivedRole != nil ? AppTheme.accent : AppTheme.danger).opacity(0.08)
                        )
                        .cornerRadius(10)

                        if let errorMessage {
                                AppMessageBanner(text: errorMessage, tint: AppTheme.danger)
                        }

                        Button {
                            errorMessage = nil
                            Task {
                                do {
                                    try await authVM.createUser(email: normalizedEmail, password: password)
                                    dismiss()
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        } label: {
                            Text("Create Account")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppTheme.accentGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(!canSubmit)
                        .opacity(canSubmit ? 1 : 0.5)

                        Button {
                            dismiss()
                        } label: {
                            Text("Back to Sign In")
                                .font(.subheadline.bold())
                                .foregroundColor(AppTheme.accent)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
