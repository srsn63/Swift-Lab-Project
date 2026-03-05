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
        VStack(spacing: 16) {
            Text("Create Account")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 10) {
                TextField("Email (name@guard.com or name@warden.com)", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                SecureField("Password (min 6 chars)", text: $password)
                    .textFieldStyle(.roundedBorder)

                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Text("Role:")
                        .foregroundStyle(.secondary)
                    Text(derivedRole?.capitalized ?? "Invalid email domain")
                        .fontWeight(.semibold)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
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
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSubmit)

            Button {
                dismiss()
            } label: {
                Text("Back to Login")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
}
