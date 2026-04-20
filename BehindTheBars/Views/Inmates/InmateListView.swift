import SwiftUI

struct InmateListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = InmateCRUDViewModel()
    @StateObject private var blocksVM = BlocksDirectoryViewModel()

    @State private var searchText = ""
    @State private var showingAdd = false
    @State private var editingInmate: Inmate?
    @State private var deletingInmate: Inmate?

    private var isGuard: Bool {
        authVM.currentUser?.role == "guard"
    }

    private var guardBlockId: String {
        BlockAssignment.normalized(authVM.currentUser?.assignedBlockId)
    }

    private var filteredInmates: [Inmate] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return vm.inmates
        }

        return vm.inmates.filter { inmate in
            inmate.fullName.lowercased().contains(query) || inmate.cellId.lowercased().contains(query)
        }
    }

    private var rosterSubtitle: String {
        if !isGuard {
            return "Manage inmate admission, placement, and sentence status with the same visual system used across the rest of the app."
        }

        if BlockAssignment.isAllBlocks(guardBlockId) {
            return "Review inmates across the entire prison with the same roster, detail, and placement style used everywhere else."
        }

        let blockLabel = blockLabel(for: guardBlockId)
        if !BlockAssignment.isUnassigned(guardBlockId) && blockLabel != "Unassigned" {
            return "Review inmates assigned to \(blockLabel) with a cleaner, consistent roster and detail view."
        }

        return "A block assignment is required before a guard can open the inmate roster."
    }

    var body: some View {
        List {
            headerSection
            summarySection
            errorSection
            contentSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppScreenBackground())
        .navigationTitle("Inmates")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search by name or cell")
        .toolbar {
            if !isGuard {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAdd = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(AppTheme.accentGradient))
                    }
                }
            }
        }
        .task {
            await blocksVM.load()
        }
        .onAppear {
            startRosterListener()
        }
        .onDisappear {
            vm.stopListener()
        }
        .sheet(isPresented: $showingAdd) {
            InmateAdmissionView(onCreated: { })
        }
        .sheet(item: $editingInmate) { inmate in
            NavigationStack {
                InmateEditorView(inmateId: inmate.id, existing: inmate) { updated in
                    guard let inmateId = inmate.id else { return }
                    try await vm.update(inmateId: inmateId, inmate: updated)
                }
            }
        }
        .alert("Delete Inmate", isPresented: deleteAlertBinding, presenting: deletingInmate) { inmate in
            Button("Cancel", role: .cancel) {
                deletingInmate = nil
            }

            Button("Delete", role: .destructive) {
                deleteInmate(inmate)
            }
        } message: { inmate in
            Text("Delete \(inmate.fullName)? This cannot be undone.")
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { deletingInmate != nil },
            set: { newValue in
                if !newValue {
                    deletingInmate = nil
                }
            }
        )
    }

    @ViewBuilder
    private var headerSection: some View {
        Section {
            AppHeroHeader(
                title: "Inmate Roster",
                subtitle: rosterSubtitle,
                icon: "person.crop.rectangle.stack.fill",
                tint: AppTheme.accent,
                badgeText: "\(filteredInmates.count)"
            )
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private var summarySection: some View {
        Section {
            AppSurfaceCard(tint: AppTheme.accent) {
                HStack {
                    summaryStat(title: "Low", count: lowSecurityCount, color: .green)
                    Spacer()
                    summaryStat(title: "Medium", count: mediumSecurityCount, color: .orange)
                    Spacer()
                    summaryStat(title: "High", count: highSecurityCount, color: .red)
                }
            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private var errorSection: some View {
        if let errorMessage = vm.errorMessage {
            Section {
                AppMessageBanner(text: errorMessage, tint: AppTheme.danger)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        if filteredInmates.isEmpty && vm.errorMessage == nil {
            Section {
                AppEmptyStateCard(
                    title: searchText.isEmpty ? "No inmates found" : "No matching inmates",
                    subtitle: searchText.isEmpty
                        ? "Admitted inmates will appear here with consistent placement and sentence details."
                        : "Try a different inmate name or cell number.",
                    icon: "person.crop.rectangle.stack",
                    tint: AppTheme.accent
                )
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } else {
            Section {
                ForEach(filteredInmates) { inmate in
                    inmateRow(for: inmate)
                }
            } header: {
                Label("Inmate Feed", systemImage: "list.bullet.rectangle.portrait")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }
        }
    }

    private var lowSecurityCount: Int {
        filteredInmates.filter { $0.securityLevel.lowercased() == "low" }.count
    }

    private var mediumSecurityCount: Int {
        filteredInmates.filter { $0.securityLevel.lowercased() == "medium" }.count
    }

    private var highSecurityCount: Int {
        filteredInmates.filter { $0.securityLevel.lowercased() == "high" }.count
    }

    private func summaryStat(title: String, count: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.inkMuted)
            Text("\(count)")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text("inmates")
                .font(.caption)
                .foregroundStyle(AppTheme.inkMuted)
        }
    }

    private func inmateRow(for inmate: Inmate) -> some View {
        NavigationLink {
            InmateDetailView(
                inmate: inmate,
                initialBlockName: blockLabel(for: inmate.blockId)
            )
        } label: {
            InmateRowCard(
                inmate: inmate,
                blockName: blockLabel(for: inmate.blockId)
            )
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if !isGuard {
                Button {
                    editingInmate = inmate
                } label: {
                    Text("Edit")
                }
                .tint(AppTheme.accent)

                Button(role: .destructive) {
                    deletingInmate = inmate
                } label: {
                    Text("Delete")
                }
            }
        }
    }

    private func deleteInmate(_ inmate: Inmate) {
        guard let inmateId = inmate.id else {
            deletingInmate = nil
            return
        }

        Task {
            try? await vm.delete(inmateId: inmateId)
        }
        deletingInmate = nil
    }

    private func startRosterListener() {
        if !isGuard {
            vm.startListener()
            return
        }

        if BlockAssignment.isUnassigned(guardBlockId) {
            vm.inmates = []
            vm.errorMessage = "You are not assigned to a block."
            return
        }

        if let specificBlockId = BlockAssignment.specificBlockId(guardBlockId) {
            vm.startListener(blockIdFilter: specificBlockId)
            return
        }

        vm.startListener()
    }

    private func blockLabel(for blockId: String) -> String {
        BlockAssignment.displayName(for: blockId, blocks: blocksVM.blocks)
    }
}

private struct InmateRowCard: View {
    let inmate: Inmate
    let blockName: String

    private var securityColor: Color {
        AppTheme.securityColor(inmate.securityLevel)
    }

    var body: some View {
        AppSurfaceCard(tint: securityColor, padding: 16) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(securityColor.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Text(String(inmate.firstName.prefix(1)) + String(inmate.lastName.prefix(1)))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(securityColor)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(inmate.fullName)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.ink)

                        if inmate.isSolitary {
                            StatusBadge(text: "Solitary", color: AppTheme.danger, small: true)
                        }
                    }

                    HStack(spacing: 10) {
                        Label(blockName, systemImage: "building.2")
                            .lineLimit(1)
                        Label(inmate.cellId, systemImage: "door.left.hand.closed")
                            .lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.inkMuted)

                    Text("Release: \(inmate.releaseDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.inkMuted)
                }

                Spacer()

                StatusBadge(
                    text: inmate.securityLevel.uppercased(),
                    color: securityColor,
                    small: true
                )
            }
        }
    }
}
