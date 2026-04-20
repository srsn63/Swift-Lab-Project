import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class GuardListViewModel: ObservableObject {
    @Published var guards: [User] = []
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?

    deinit { listener?.remove() }

    func startListener() {
        listener?.remove()
        errorMessage = nil

        listener = FirebaseManager.shared.usersRef
            .whereField("role", isEqualTo: "guard")
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let err {
                    self.errorMessage = err.localizedDescription
                    return
                }
                let list = snap?.documents.compactMap { try? $0.data(as: User.self) } ?? []
                self.guards = list.sorted { $0.email < $1.email }
            }
    }

    func stopListener() {
        listener?.remove()
        listener = nil
    }

    func deleteGuardDoc(uid: String) async throws {
        try await FirebaseManager.shared.usersRef.document(uid).delete()
    }

    func updateGuard(uid: String, fullName: String, badge: String, blockId: String, dutyStartAt: Date) async throws {
        try await FirebaseManager.shared.usersRef.document(uid).updateData([
            "fullName": fullName,
            "badgeNumber": badge,
            "assignedBlockId": BlockAssignment.normalized(blockId),
            "shift": ShiftDutySchedule.initialShiftName(for: dutyStartAt),
            "dutyStartAt": Timestamp(date: dutyStartAt)
        ])
    }
}

struct GuardListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = GuardListViewModel()
    @StateObject private var blocksVM = BlocksDirectoryViewModel()

    @State private var editing: User?
    @State private var deleting: User?

    var body: some View {
        List {
            Section {
                AppHeroHeader(
                    title: "Guard Directory",
                    subtitle: "Review block assignments, badge details, and live 8-hour duty countdowns for every guard.",
                    icon: "shield.fill",
                    tint: AppTheme.accent,
                    badgeText: "\(vm.guards.count)"
                )
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if let err = vm.errorMessage {
                Section {
                    AppMessageBanner(text: err, tint: AppTheme.danger)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if vm.guards.isEmpty && vm.errorMessage == nil {
                Section {
                    AppEmptyStateCard(
                        title: "No guards found",
                        subtitle: "Approved guard accounts will appear here with their block assignments and live duty status.",
                        icon: "shield.lefthalf.filled",
                        tint: AppTheme.accent
                    )
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                Section {
                    ForEach(vm.guards) { guardUser in
                        GuardRowCard(
                            user: guardUser,
                            blockName: getBlockName(id: guardUser.assignedBlockId ?? ""),
                            displayName: displayName(for: guardUser),
                            showsEmail: shouldShowEmail(for: guardUser),
                            canDelete: authVM.currentUser?.role == "admin" || authVM.currentUser?.role == "warden",
                            onEdit: { editing = guardUser },
                            onDelete: { deleting = guardUser }
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                } header: {
                    Label("Active Guards", systemImage: "person.2.fill")
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppScreenBackground())
        .navigationTitle("Guards")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await blocksVM.load()
        }
        .onAppear { vm.startListener() }
        .onDisappear { vm.stopListener() }
        .sheet(item: $editing) { guardUser in
            NavigationStack {
                GuardEditorView(user: guardUser) { fullName, badge, blockId, dutyStartAt in
                    try await vm.updateGuard(
                        uid: guardUser.uid,
                        fullName: fullName,
                        badge: badge,
                        blockId: blockId,
                        dutyStartAt: dutyStartAt
                    )
                }
            }
        }
        .alert("Delete Guard", isPresented: .constant(deleting != nil), presenting: deleting) { user in
            Button("Cancel", role: .cancel) {
                deleting = nil
            }
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await vm.deleteGuardDoc(uid: user.uid)
                    } catch {
                        vm.errorMessage = error.localizedDescription
                    }
                }
                deleting = nil
            }
        } message: { user in
            Text("Delete \(displayName(for: user))? This cannot be undone.")
        }
    }

    private func getBlockName(id: String) -> String {
        BlockAssignment.displayName(for: id, blocks: blocksVM.blocks)
    }

    private func displayName(for user: User) -> String {
        let name = (user.fullName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? user.email : name
    }

    private func shouldShowEmail(for user: User) -> Bool {
        let name = (user.fullName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return !name.isEmpty
    }
}

private struct GuardRowCard: View {
    let user: User
    let blockName: String
    let displayName: String
    let showsEmail: Bool
    let canDelete: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        AppSurfaceCard(tint: AppTheme.accent, padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.accent.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Image(systemName: "shield.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.accent)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayName)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.ink)
                        if showsEmail {
                            Text(user.email)
                                .font(.caption)
                                .foregroundStyle(AppTheme.inkMuted)
                        }
                    }

                    Spacer()

                    StatusBadge(
                        text: blockName,
                        color: BlockAssignment.isUnassigned(user.assignedBlockId) ? .secondary : AppTheme.accent,
                        small: true
                    )
                }

                if let badge = user.badgeNumber, !badge.isEmpty {
                    Label(badge, systemImage: "number")
                        .font(.caption)
                        .foregroundStyle(AppTheme.inkMuted)
                }

                if let dutyStartAt = user.dutyAnchorDate {
                    GuardDutyStatusLabel(dutyStartAt: dutyStartAt)
                } else {
                    Label("Duty schedule not assigned", systemImage: "clock.badge.exclamationmark")
                        .font(.caption)
                        .foregroundStyle(AppTheme.inkMuted)
                }

                HStack(spacing: 10) {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                            .font(.caption.bold())
                            .foregroundColor(AppTheme.accent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(AppTheme.accent.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)

                    if canDelete {
                        Button(action: onDelete) {
                            Label("Delete", systemImage: "trash")
                                .font(.caption.bold())
                                .foregroundColor(AppTheme.danger)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(AppTheme.danger.opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct GuardDutyStatusLabel: View {
    let dutyStartAt: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 8) {
                Image(systemName: isOnDuty(now: context.date) ? "checkmark.circle.fill" : "clock.badge")
                Text(primaryText(now: context.date))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(isOnDuty(now: context.date) ? AppTheme.success : AppTheme.warning)
        }
    }

    private func status(now: Date) -> ShiftDutyScheduleStatus {
        ShiftDutySchedule.status(for: dutyStartAt, now: now)
    }

    private func isOnDuty(now: Date) -> Bool {
        status(now: now).isOnDuty
    }

    private func primaryText(now: Date) -> String {
        let currentStatus = status(now: now)
        let countdown = ShiftDutySchedule.countdownString(to: currentStatus.nextChangeDate, now: now)

        if currentStatus.isOnDuty {
            return "On duty, ends in \(countdown)"
        }

        return "Off duty, starts in \(countdown)"
    }
}
