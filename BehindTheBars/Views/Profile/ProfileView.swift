import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = ProfileViewModel()

    @State private var showToast = false
    @State private var toastText = ""

    private var canEditAssignment: Bool {
        false
    }

    private var initials: String {
        let name = authVM.currentUser?.fullName ?? authVM.currentUser?.email ?? ""
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    AppSurfaceCard(tint: roleColor) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accentGradient)
                                    .frame(width: 72, height: 72)
                                Text(initials)
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text(authVM.currentUser?.email ?? "")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.ink)
                                Text("Profile and identity settings")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.inkMuted)
                                StatusBadge(
                                    text: authVM.currentUser?.role.uppercased() ?? "",
                                    color: roleColor
                                )
                            }
                        }
                    }
                }
                .listRowBackground(Color.clear)

                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(AppTheme.accent)
                            .frame(width: 20)
                        Text(authVM.currentUser?.email ?? "-")
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "shield.lefthalf.filled")
                            .foregroundColor(AppTheme.accent)
                            .frame(width: 20)
                        Text(authVM.currentUser?.role.capitalized ?? "-")
                    }

                    if authVM.currentUser?.role == "guard" {
                        HStack(spacing: 12) {
                            Image(systemName: "building.2")
                                .foregroundColor(AppTheme.accent)
                                .frame(width: 20)
                            Text("Block: \(authVM.currentUser?.assignedBlockId ?? "-")")
                        }
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal")
                            .foregroundColor(AppTheme.success)
                            .frame(width: 20)
                        Text("Status: \(authVM.currentUser?.status ?? "-")")
                    }
                } header: {
                    Label("Account", systemImage: "person.circle")
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.accent)
                }
                .listRowBackground(AppTheme.surfaceElevated)

                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .foregroundColor(AppTheme.accent)
                            .frame(width: 20)
                        TextField("Full name", text: $vm.fullName)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "number")
                            .foregroundColor(AppTheme.accent)
                            .frame(width: 20)
                        TextField("Badge number", text: $vm.badgeNumber)
                    }

                    if authVM.currentUser?.role == "guard" {
                        HStack(spacing: 12) {
                            Image(systemName: "building.2")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            TextField("Assigned block id", text: $vm.assignedBlockId)
                                .disabled(true)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Label("Personal Details", systemImage: "pencil")
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.accent)
                }
                .listRowBackground(AppTheme.surfaceElevated)

                if let err = vm.errorMessage {
                    Section {
                        AppMessageBanner(text: err, tint: AppTheme.danger)
                    }
                    .listRowBackground(Color.clear)
                }

                Section {
                    Button {
                        Task {
                            guard let uid = authVM.currentUser?.uid else { return }
                            do {
                                try await vm.save(uid: uid, includeAssignedBlockId: canEditAssignment)
                                toastText = "Profile updated"
                                showToast = true
                                await authVM.fetchCurrentUser()
                            } catch {
                                vm.errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Label("Save Changes", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppTheme.accentGradient)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(AppScreenBackground())
            .onAppear {
                if let user = authVM.currentUser {
                    vm.load(from: user)
                }
            }
        }
        .toast(isPresented: $showToast, text: toastText, seconds: 1.2)
    }

    private var roleColor: Color {
        AppTheme.roleColor(authVM.currentUser?.role)
    }
}
