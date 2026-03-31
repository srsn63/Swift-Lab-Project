import SwiftUI

struct AdminUserManagementView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = AdminUserManagementViewModel()

    @State private var editingUser: User?
    @State private var deletingUser: User?

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Total Users")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(vm.users.count)")
                            .font(.title3.bold())
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Pending")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(vm.pendingCount)")
                            .font(.title3.bold())
                            .foregroundColor(AppTheme.warning)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Approved")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(vm.approvedCount)")
                            .font(.title3.bold())
                            .foregroundColor(AppTheme.success)
                    }
                }
            }

            Section {
                HStack(spacing: 10) {
                    Menu {
                        Button("All Roles") { vm.selectedRole = "all" }
                        Button("Admin") { vm.selectedRole = "admin" }
                        Button("Warden") { vm.selectedRole = "warden" }
                        Button("Guard") { vm.selectedRole = "guard" }
                    } label: {
                        Label(vm.selectedRole == "all" ? "All Roles" : vm.selectedRole.capitalized, systemImage: "person.2")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.accent.opacity(0.12))
                            .cornerRadius(8)
                    }

                    Menu {
                        Button("All Statuses") { vm.selectedStatus = "all" }
                        Button("Pending") { vm.selectedStatus = "pending" }
                        Button("Approved") { vm.selectedStatus = "approved" }
                        Button("Denied") { vm.selectedStatus = "denied" }
                    } label: {
                        Label(vm.selectedStatus == "all" ? "All Statuses" : vm.selectedStatus.capitalized, systemImage: "line.3.horizontal.decrease.circle")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.accent.opacity(0.12))
                            .cornerRadius(8)
                    }
                }
            }

            if let err = vm.errorMessage {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppTheme.danger)
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.danger)
                    }
                }
            }

            if vm.filteredUsers.isEmpty && vm.errorMessage == nil {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary.opacity(0.4))
                            Text(vm.searchText.isEmpty ? "No users found" : "No results for \"\(vm.searchText)\"")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 24)
                        Spacer()
                    }
                }
            }

            ForEach(vm.filteredUsers) { user in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accent.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "person.fill")
                                .foregroundColor(AppTheme.accent)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.displayName(for: user))
                                .font(.subheadline.bold())
                            if vm.showEmailSubtitle(for: user) {
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 6) {
                            StatusBadge(text: user.role.capitalized, color: roleColor(for: user.role), small: true)
                            StatusBadge(text: user.status.capitalized, color: statusColor(for: user.status), small: true)
                        }
                    }

                    if user.role == "guard" {
                        HStack(spacing: 6) {
                            Label(vm.blockName(for: user.assignedBlockId), systemImage: "building.2")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let badge = user.badgeNumber, !badge.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("•")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Label(badge, systemImage: "number")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        Button {
                            editingUser = user
                        } label: {
                            Label("Edit", systemImage: "pencil")
                                .font(.caption.bold())
                                .foregroundColor(AppTheme.accent)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppTheme.accent.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)

                        if user.status == "pending" {
                            Button {
                                Task {
                                    do {
                                        try await vm.setApproval(uid: user.uid, approved: true, status: "approved")
                                    } catch {
                                        vm.errorMessage = error.localizedDescription
                                    }
                                }
                            } label: {
                                Label("Approve", systemImage: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.success)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }

                        if canDelete(user: user) {
                            Button {
                                deletingUser = user
                            } label: {
                                Label("Delete", systemImage: "trash")
                                    .font(.caption.bold())
                                    .foregroundColor(AppTheme.danger)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.danger.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Manage Users")
        .searchable(text: $vm.searchText, prompt: "Search by name, email, or badge")
        .task {
            await vm.loadBlocks()
        }
        .onAppear {
            vm.startListener()
        }
        .onDisappear {
            vm.stopListener()
        }
        .sheet(item: $editingUser) { user in
            NavigationStack {
                AdminUserEditorView(
                    user: user,
                    blocks: vm.blocks
                ) { role, fullName, badge, assignedBlockId, approved, status in
                    try await vm.updateUser(
                        uid: user.uid,
                        role: role,
                        fullName: fullName,
                        badgeNumber: badge,
                        assignedBlockId: assignedBlockId,
                        approved: approved,
                        status: status
                    )
                }
            }
        }
        .alert("Delete User", isPresented: .constant(deletingUser != nil), presenting: deletingUser) { user in
            Button("Cancel", role: .cancel) {
                deletingUser = nil
            }
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await vm.deleteUser(uid: user.uid)
                    } catch {
                        vm.errorMessage = error.localizedDescription
                    }
                }
                deletingUser = nil
            }
        } message: { user in
            Text("Delete \(vm.displayName(for: user))? This cannot be undone.")
        }
    }

    private func roleColor(for role: String) -> Color {
        switch role {
        case "admin": return .purple
        case "warden": return AppTheme.accent
        case "guard": return .teal
        default: return .gray
        }
    }

    private func statusColor(for status: String) -> Color {
        switch status {
        case "approved": return AppTheme.success
        case "pending": return AppTheme.warning
        case "denied": return AppTheme.danger
        default: return .gray
        }
    }

    private func canDelete(user: User) -> Bool {
        authVM.currentUser?.uid != user.uid
    }
}

private struct AdminUserEditorView: View {
    let user: User
    let blocks: [Block]
    let onSave: (String, String, String, String, Bool, String) async throws -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var role: String = "guard"
    @State private var fullName: String = ""
    @State private var badgeNumber: String = ""
    @State private var assignedBlockId: String = ""
    @State private var approved: Bool = false
    @State private var status: String = "pending"
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(AppTheme.accent)
                        .frame(width: 20)
                    Text(user.email)
                }
            } header: {
                Label("Account", systemImage: "person.circle")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }

            Section {
                Picker("Role", selection: $role) {
                    Text("Admin").tag("admin")
                    Text("Warden").tag("warden")
                    Text("Guard").tag("guard")
                }

                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .foregroundColor(AppTheme.accent)
                        .frame(width: 20)
                    TextField("Full name", text: $fullName)
                }

                HStack(spacing: 12) {
                    Image(systemName: "number")
                        .foregroundColor(AppTheme.accent)
                        .frame(width: 20)
                    TextField("Badge number", text: $badgeNumber)
                }
            } header: {
                Label("Identity", systemImage: "person.text.rectangle")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }

            if role == "guard" {
                Section {
                    Menu {
                        Button("Unassigned") { assignedBlockId = "" }
                        ForEach(blocks) { block in
                            Button(block.name) { assignedBlockId = block.id ?? "" }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "building.2")
                                .foregroundColor(AppTheme.accent)
                                .frame(width: 20)
                            Text("Assigned Block")
                            Spacer()
                            Text(currentBlockName)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Label("Assignment", systemImage: "mappin.and.ellipse")
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.accent)
                }
            }

            Section {
                Toggle("Approved", isOn: $approved)

                Picker("Status", selection: $status) {
                    Text("Pending").tag("pending")
                    Text("Approved").tag("approved")
                    Text("Denied").tag("denied")
                }
            } header: {
                Label("Access", systemImage: "checkmark.shield")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }

            if let err = errorMessage {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppTheme.danger)
                        Text(err)
                            .foregroundStyle(AppTheme.danger)
                            .font(.footnote)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Edit User")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { save() }
                    .fontWeight(.semibold)
            }
        }
        .onAppear {
            role = user.role
            fullName = user.fullName ?? ""
            badgeNumber = user.badgeNumber ?? ""
            assignedBlockId = user.assignedBlockId ?? ""
            approved = user.approved
            status = user.status
        }
    }

    private var currentBlockName: String {
        if assignedBlockId.isEmpty { return "Unassigned" }
        return blocks.first(where: { $0.id == assignedBlockId })?.name ?? assignedBlockId
    }

    private func save() {
        errorMessage = nil
        Task {
            do {
                try await onSave(role, fullName, badgeNumber, assignedBlockId, approved, status)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
