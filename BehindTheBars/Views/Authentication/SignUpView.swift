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
            AppTheme.headerGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 36))
                                .foregroundColor(.white.opacity(0.9))
                        }

                        Text("Create Account")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 30)

                    // Form card
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
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.footnote)
                                Text(errorMessage)
                                    .font(.footnote)
                            }
                            .foregroundColor(AppTheme.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppTheme.accentGradient)
                                .cornerRadius(12)
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
                    .padding(24)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(24)
                    .shadow(color: .black.opacity(0.12), radius: 20, y: 10)
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
