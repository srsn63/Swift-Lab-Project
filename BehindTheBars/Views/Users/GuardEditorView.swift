import SwiftUI

struct GuardEditorView: View {
    let user: User
    let onSave: (String, String, String) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var fullName: String = ""
    @State private var badgeNumber: String = ""
    @State private var assignedBlock: String = ""
    @State private var errorMessage: String?

    @State private var showToast = false
    @State private var toastText = ""

    var body: some View {
        Form {
            Section("Account") {
                Text(user.email)
                Text(user.role)
            }

            Section("Editable") {
                TextField("Full name", text: $fullName)
                TextField("Badge number", text: $badgeNumber)
                TextField("Assigned block", text: $assignedBlock)
            }

            if let errorMessage {
                Section { Text(errorMessage).foregroundColor(.red) }
            }
        }
        .navigationTitle("Edit Guard")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    errorMessage = nil
                    Task {
                        do {
                            try await onSave(fullName, badgeNumber, assignedBlock)
                            toastText = "Guard updated"
                            withAnimation { showToast = true }
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
        .onAppear {
            fullName = user.fullName ?? ""
            badgeNumber = user.badgeNumber ?? ""
            assignedBlock = user.assignedBlockId ?? ""
        }
        .toast(isPresented: $showToast, text: toastText)
    }
}
