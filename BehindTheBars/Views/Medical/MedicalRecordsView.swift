import SwiftUI

enum MedicalRecordsAccessMode {
    case guardManage
    case wardenReadOnly

    var title: String {
        switch self {
        case .guardManage:
            return "Medical Records"
        case .wardenReadOnly:
            return "Medical Status"
        }
    }
}

struct MedicalRecordsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = MedicalRecordsViewModel()

    let accessMode: MedicalRecordsAccessMode

    @State private var searchText = ""
    @State private var showingAdd = false
    @State private var editingRecord: MedicalRecord?
    @State private var deletingRecord: MedicalRecord?

    private var currentUser: User? { authVM.currentUser }

    private var canManageRecords: Bool {
        accessMode == .guardManage
            && currentUser?.role == "guard"
            && !guardBlockId.isEmpty
    }

    private var guardBlockId: String {
        currentUser?.assignedBlockId ?? ""
    }

    private var filteredRecords: [MedicalRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty { return vm.records }

        return vm.records.filter { record in
            record.inmateName.lowercased().contains(query)
                || record.doctorName.lowercased().contains(query)
                || record.medicalStatus.displayName.lowercased().contains(query)
                || vm.blockName(for: record.blockId).lowercased().contains(query)
        }
    }

    private var heroSubtitle: String {
        switch accessMode {
        case .guardManage:
            return "Track inmate treatment, assign any active prison doctor, and keep records current."
        case .wardenReadOnly:
            return "Review block-level health updates and monitor medical status across the prison."
        }
    }

    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No matching records"
        }

        switch accessMode {
        case .guardManage:
            return canManageRecords ? "No medical records yet" : "Block assignment required"
        case .wardenReadOnly:
            return "No medical updates yet"
        }
    }

    private var emptyStateSubtitle: String {
        if !searchText.isEmpty {
            return "Try searching by inmate name, doctor, block, or medical status."
        }

        switch accessMode {
        case .guardManage:
            return canManageRecords
                ? "Medical records created by guards in this block will appear here."
                : "Assign a block to this guard before managing medical records."
        case .wardenReadOnly:
            return "Medical records will appear here once guards begin submitting updates."
        }
    }

    private var sectionHeaderTitle: String {
        accessMode == .guardManage ? "Record Feed" : "Medical Feed"
    }

    var body: some View {
        List {
            Section {
                AppHeroHeader(
                    title: accessMode.title,
                    subtitle: heroSubtitle,
                    icon: accessMode == .guardManage ? "cross.case.fill" : "waveform.path.ecg",
                    tint: .red,
                    badgeText: accessMode == .guardManage ? "Guard" : "Warden"
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

            if filteredRecords.isEmpty && vm.errorMessage == nil {
                Section {
                    AppEmptyStateCard(
                        title: emptyStateTitle,
                        subtitle: emptyStateSubtitle,
                        icon: accessMode == .guardManage ? "cross.case.circle" : "waveform.path.ecg",
                        tint: .red
                    )
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else if !filteredRecords.isEmpty {
                Section {
                    ForEach(filteredRecords) { record in
                        NavigationLink {
                            MedicalRecordDetailView(
                                record: record,
                                accessMode: accessMode,
                                blockName: vm.blockName(for: record.blockId)
                            )
                        } label: {
                            MedicalRecordRowView(
                                record: record,
                                blockName: vm.blockName(for: record.blockId),
                                showsBlock: accessMode == .wardenReadOnly
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if canManageRecords {
                                Button {
                                    editingRecord = record
                                } label: {
                                    Text("Edit")
                                }
                                .tint(AppTheme.accent)

                                Button(role: .destructive) {
                                    deletingRecord = record
                                } label: {
                                    Text("Delete")
                                }
                            }
                        }
                    }
                } header: {
                    Label(sectionHeaderTitle, systemImage: "list.bullet.rectangle.portrait")
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppScreenBackground())
        .navigationTitle(accessMode.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: searchPrompt)
        .toolbar {
            if accessMode == .guardManage {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(AppTheme.accentGradient))
                    }
                    .disabled(!canManageRecords)
                }
            }
        }
        .task(id: currentUser?.uid) {
            await refreshData()
        }
        .onDisappear {
            vm.stopListener()
        }
        .sheet(isPresented: $showingAdd) {
            if let currentUser {
                NavigationStack {
                    MedicalRecordEditorView(vm: vm, existing: nil, currentUser: currentUser) { newRecord in
                        try await vm.create(record: newRecord, currentUser: currentUser)
                    }
                }
            }
        }
        .sheet(item: $editingRecord) { record in
            if let currentUser {
                NavigationStack {
                    MedicalRecordEditorView(vm: vm, existing: record, currentUser: currentUser) { updatedRecord in
                        guard let recordId = record.id else { return }
                        try await vm.update(recordId: recordId, record: updatedRecord, currentUser: currentUser)
                    }
                }
            }
        }
        .alert("Delete Medical Record", isPresented: .constant(deletingRecord != nil), presenting: deletingRecord) { record in
            Button("Cancel", role: .cancel) {
                deletingRecord = nil
            }
            Button("Delete", role: .destructive) {
                guard let currentUser else {
                    deletingRecord = nil
                    return
                }
                Task {
                    do {
                        try await vm.delete(record: record, currentUser: currentUser)
                    } catch {
                        vm.errorMessage = error.localizedDescription
                    }
                }
                deletingRecord = nil
            }
        } message: { record in
            Text("Delete the medical record for \(record.inmateName)? This cannot be undone.")
        }
    }

    private var searchPrompt: String {
        switch accessMode {
        case .guardManage:
            return "Search by inmate, doctor, or status"
        case .wardenReadOnly:
            return "Search by inmate, block, or status"
        }
    }

    private func refreshData() async {
        guard let currentUser else { return }
        vm.startListener(for: currentUser)
        await vm.loadBlocks()

        if accessMode == .guardManage {
            await vm.loadEditorData(for: currentUser)
        } else {
            vm.availableInmates = []
            vm.availableDoctors = []
        }
    }
}

private struct MedicalRecordRowView: View {
    let record: MedicalRecord
    let blockName: String
    let showsBlock: Bool

    var body: some View {
        AppSurfaceCard(tint: record.medicalStatus.color, padding: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(record.medicalStatus.color.opacity(0.12))
                        .frame(width: 46, height: 46)
                    Image(systemName: record.medicalStatus.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(record.medicalStatus.color)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(record.inmateName)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.ink)

                    Text(record.conditionSummary)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.inkMuted)
                        .lineLimit(2)

                    HStack(spacing: 10) {
                        Label(record.doctorName, systemImage: "stethoscope")
                            .lineLimit(1)

                        if showsBlock {
                            Label(blockName, systemImage: "building.2")
                                .lineLimit(1)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.inkMuted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    StatusBadge(
                        text: record.medicalStatus.displayName,
                        color: record.medicalStatus.color,
                        small: true
                    )
                    Text(record.statusUpdatedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.inkMuted)
                }
            }
        }
    }
}

private struct MedicalRecordDetailView: View {
    let record: MedicalRecord
    let accessMode: MedicalRecordsAccessMode
    let blockName: String

    var body: some View {
        ZStack {
            AppScreenBackground()

            ScrollView {
                VStack(spacing: 18) {
                    AppHeroHeader(
                        title: record.inmateName,
                        subtitle: "Assigned doctor: \(record.doctorName)",
                        icon: record.medicalStatus.icon,
                        tint: record.medicalStatus.color,
                        badgeText: record.medicalStatus.displayName
                    )

                    AppSurfaceCard(tint: record.medicalStatus.color) {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Timeline", systemImage: "calendar.badge.clock")
                                .font(.caption.bold())
                                .foregroundColor(record.medicalStatus.color)

                            InfoRow(label: "Status Date", value: record.statusUpdatedAt.formatted(date: .long, time: .omitted))
                            InfoRow(label: "Created", value: record.createdAt.formatted(date: .long, time: .shortened))
                            InfoRow(label: "Updated", value: record.updatedAt.formatted(date: .long, time: .shortened))
                            InfoRow(label: "Block", value: blockName)
                        }
                    }

                    AppSurfaceCard(tint: AppTheme.accent) {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Assignment", systemImage: "person.2.fill")
                                .font(.caption.bold())
                                .foregroundColor(AppTheme.accent)

                            InfoRow(label: "Inmate", value: record.inmateName)
                            InfoRow(label: "Doctor", value: record.doctorName)
                            InfoRow(label: "Status", value: record.medicalStatus.displayName)

                            if accessMode == .guardManage {
                                InfoRow(label: "Created By", value: record.createdByName)
                            }
                        }
                    }

                    if accessMode == .guardManage {
                        AppSurfaceCard(tint: .red) {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("Medical Summary", systemImage: "cross.case.fill")
                                    .font(.caption.bold())
                                    .foregroundColor(.red)

                                Text(record.conditionSummary)
                                    .font(.body)
                                    .foregroundStyle(AppTheme.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Divider()

                                Label("Treatment Notes", systemImage: "note.text")
                                    .font(.caption.bold())
                                    .foregroundColor(AppTheme.accent)

                                Text(record.treatmentNotes.isEmpty ? "No treatment notes added." : record.treatmentNotes)
                                    .font(.body)
                                    .foregroundStyle(record.treatmentNotes.isEmpty ? AppTheme.inkMuted : AppTheme.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(accessMode == .guardManage ? "Record Detail" : "Status Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
