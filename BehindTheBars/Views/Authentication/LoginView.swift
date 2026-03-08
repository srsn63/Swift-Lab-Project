import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    private var normalizedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.headerGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Branding
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                Image(systemName: "building.columns.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(.white.opacity(0.9))
                            }

                            Text("Behind The Bars")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)

                            Text("Prison Management System")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.65))
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 36)

                        // Login card
                        VStack(spacing: 20) {
                            Text("Sign In")
                                .font(.title3.bold())
                                .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(spacing: 14) {
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(AppTheme.accent)
                                        .frame(width: 20)
                                    TextField("Email", text: $email)
                                        .textInputAutocapitalization(.never)
                                        .keyboardType(.emailAddress)
                                        .autocorrectionDisabled()
                                }
                                .padding(14)
                                .background(Color(UIColor.tertiarySystemFill))
                                .cornerRadius(12)

                                HStack(spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(AppTheme.accent)
                                        .frame(width: 20)
                                    SecureField("Password", text: $password)
                                }
                                .padding(14)
                                .background(Color(UIColor.tertiarySystemFill))
                                .cornerRadius(12)
                            }

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
                                        try await authVM.signIn(email: normalizedEmail, password: password)
                                    } catch {
                                        errorMessage = error.localizedDescription
                                    }
                                }
                            } label: {
                                Text("Sign In")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(AppTheme.accentGradient)
                                    .cornerRadius(12)
                            }
                            .disabled(normalizedEmail.isEmpty || password.isEmpty)
                            .opacity((normalizedEmail.isEmpty || password.isEmpty) ? 0.5 : 1)

                            HStack {
                                Rectangle().frame(height: 1).foregroundColor(Color(UIColor.separator))
                                Text("OR")
                                    .font(.caption2.bold())
                                    .foregroundColor(.secondary)
                                Rectangle().frame(height: 1).foregroundColor(Color(UIColor.separator))
                            }
                            .padding(.vertical, 4)

                            NavigationLink {
                                SignUpView()
                                    .environmentObject(authVM)
                            } label: {
                                Text("Create New Account")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(AppTheme.accent.opacity(0.08))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1)
                                    )
                            }
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
}
