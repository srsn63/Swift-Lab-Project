import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = ProfileViewModel()

    @State private var showToast = false
    @State private var toastText = ""

    private var canEditAssignment: Bool {
        false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Account")) {
                    Text(authVM.currentUser?.email ?? "--")
                    Text(authVM.currentUser?.role ?? "--")

                    if authVM.currentUser?.role == "guard" {
                        Text("Assigned Block ID: \(authVM.currentUser?.assignedBlockId ?? "--")")
                            .foregroundStyle(.secondary)
                    }

                    Text("Status: \(authVM.currentUser?.status ?? "--")")
                        .foregroundStyle(.secondary)
                }

                Section(header: Text("Personal details")) {
                    TextField("Full name", text: $vm.fullName)
                    TextField("Badge number", text: $vm.badgeNumber)

                    if authVM.currentUser?.role == "guard" {
                        TextField("Assigned block id", text: $vm.assignedBlockId)
                            .disabled(true)
                            .foregroundStyle(.secondary)
                    }
                }

                if let err = vm.errorMessage {
                    Section {
                        Text(err).foregroundStyle(.red)
                    }
                }

                Section {
                    Button("Save") {
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
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                if let u = authVM.currentUser {
                    vm.load(from: u)
                }
            }
        }
        // Uses your existing Components/Toast.swift extension (ToastView + .toast modifier)
        .toast(isPresented: $showToast, text: toastText, seconds: 1.2)
    }
}
