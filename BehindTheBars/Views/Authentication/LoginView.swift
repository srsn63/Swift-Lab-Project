import SwiftUI
import LocalAuthentication
import Security
#if os(macOS)
import AppKit
#endif

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var rememberCredentials = true
    @State private var hasSavedCredentials = false
    @State private var biometricAvailable = false
    @State private var biometricLabel = "Biometrics"
    @State private var isLoading = false

    private let credentialVault = CredentialVault()
    private let biometricAuthenticator = BiometricAuthenticator()

    private var normalizedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var canSignIn: Bool {
        !normalizedEmail.isEmpty && !password.isEmpty && !isLoading
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
                                        .loginEmailInputBehavior()
                                }
                                .padding(14)
                                .background(Color.loginInputFill)
                                .cornerRadius(12)

                                HStack(spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(AppTheme.accent)
                                        .frame(width: 20)
                                    SecureField("Password", text: $password)
                                }
                                .padding(14)
                                .background(Color.loginInputFill)
                                .cornerRadius(12)

                                Toggle(isOn: $rememberCredentials) {
                                    Text("Remember credentials on this device")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .toggleStyle(.switch)
                                .tint(AppTheme.accent)
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
                                signInWithPassword()
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppTheme.accentGradient)
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                            .tint(.white)
                                    } else {
                                        Text("Sign In")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                            }
                            .disabled(!canSignIn)
                            .opacity(canSignIn ? 1 : 0.5)

                            if hasSavedCredentials {
                                Button {
                                    signInWithBiometrics()
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "touchid")
                                        Text("Quick Sign In with \(biometricLabel)")
                                            .fontWeight(.semibold)
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(AppTheme.accent.opacity(0.08))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppTheme.accent.opacity(0.22), lineWidth: 1)
                                    )
                                }
                                .disabled(!biometricAvailable || isLoading)
                                .opacity((!biometricAvailable || isLoading) ? 0.55 : 1)
                            }

                            HStack {
                                Rectangle().frame(height: 1).foregroundColor(Color.loginSeparator)
                                Text("OR")
                                    .font(.caption2.bold())
                                    .foregroundColor(.secondary)
                                Rectangle().frame(height: 1).foregroundColor(Color.loginSeparator)
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
                        .background(Color.loginCardBackground)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.12), radius: 20, y: 10)
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear(perform: prepareQuickSignIn)
        }
    }

    private func signInWithPassword() {
        errorMessage = nil

        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                try await authVM.signIn(email: normalizedEmail, password: password)
                try persistCredentialPreference()
                prepareQuickSignIn()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func signInWithBiometrics() {
        errorMessage = nil

        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                try await biometricAuthenticator.authenticate(reason: "Authenticate to sign in to Behind The Bars")
                guard let saved = try credentialVault.load() else {
                    errorMessage = "No saved credentials were found on this device."
                    return
                }

                email = saved.email
                password = saved.password
                try await authVM.signIn(email: saved.email, password: saved.password)
                try persistCredentialPreference()
                prepareQuickSignIn()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func prepareQuickSignIn() {
        biometricAvailable = biometricAuthenticator.canAuthenticate()
        biometricLabel = biometricAuthenticator.biometricLabel()

        do {
            if let saved = try credentialVault.load() {
                hasSavedCredentials = true
                if email.isEmpty {
                    email = saved.email
                }
            } else {
                hasSavedCredentials = false
            }
        } catch {
            hasSavedCredentials = false
        }
    }

    private func persistCredentialPreference() throws {
        if rememberCredentials {
            try credentialVault.save(email: normalizedEmail, password: password)
        } else {
            credentialVault.clear()
        }
    }
}

private struct SavedCredentials: Codable {
    let email: String
    let password: String
}

private enum CredentialVaultError: LocalizedError {
    case decodeFailed
    case keychain(OSStatus)

    var errorDescription: String? {
        switch self {
        case .decodeFailed:
            return "Saved sign-in data appears corrupted. Please sign in manually once."
        case .keychain(let status):
            let message = SecCopyErrorMessageString(status, nil) as String? ?? "status code \(status)"
            return "Could not access secure credentials (\(message))."
        }
    }
}

private final class CredentialVault {
    private let service = "na.BehindTheBars.savedCredentials"
    private let account = "primary"

    func save(email: String, password: String) throws {
        let payload = SavedCredentials(email: email, password: password)
        let encoded = try JSONEncoder().encode(payload)

        let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData as String: encoded] as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = encoded
#if !os(macOS)
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
#endif
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw CredentialVaultError.keychain(addStatus)
            }
            return
        }

        guard updateStatus == errSecSuccess else {
            throw CredentialVaultError.keychain(updateStatus)
        }
    }

    func load() throws -> SavedCredentials? {
        var search = query
        search[kSecMatchLimit as String] = kSecMatchLimitOne
        search[kSecReturnData as String] = kCFBooleanTrue

        var item: CFTypeRef?
        let status = SecItemCopyMatching(search as CFDictionary, &item)
        switch status {
        case errSecItemNotFound:
            return nil
        case errSecSuccess:
            guard let data = item as? Data else {
                throw CredentialVaultError.decodeFailed
            }
            do {
                return try JSONDecoder().decode(SavedCredentials.self, from: data)
            } catch {
                throw CredentialVaultError.decodeFailed
            }
        default:
            throw CredentialVaultError.keychain(status)
        }
    }

    func clear() {
        SecItemDelete(query as CFDictionary)
    }

    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

private enum BiometricAuthError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Biometric authentication is unavailable on this device."
        }
    }
}

private final class BiometricAuthenticator {
    func canAuthenticate() -> Bool {
        var error: NSError?
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func biometricLabel() -> String {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Biometrics"
        }
    }

    func authenticate(reason: String) async throws {
        let context = LAContext()
        context.localizedCancelTitle = "Use Password"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw BiometricAuthError.unavailable
        }

        _ = try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        )
    }
}

private extension Color {
    static var loginInputFill: Color {
#if os(macOS)
        return Color(nsColor: .controlBackgroundColor)
#else
        return Color(uiColor: .tertiarySystemFill)
#endif
    }

    static var loginCardBackground: Color {
#if os(macOS)
        return Color(nsColor: .windowBackgroundColor)
#else
        return Color(uiColor: .systemBackground)
#endif
    }

    static var loginSeparator: Color {
#if os(macOS)
        return Color(nsColor: .separatorColor)
#else
        return Color(uiColor: .separator)
#endif
    }
}

private extension View {
    @ViewBuilder
    func loginEmailInputBehavior() -> some View {
#if os(macOS)
        self
#else
        self
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .autocorrectionDisabled()
#endif
    }
}
