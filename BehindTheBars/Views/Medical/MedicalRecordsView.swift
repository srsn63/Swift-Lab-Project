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

    var body: some View {
        List {
            if let err = vm.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppTheme.danger)
                    Text(err)
                        .foregroundStyle(AppTheme.danger)
                        .font(.footnote)
                }
            }

            if filteredRecords.isEmpty && vm.errorMessage == nil {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: accessMode == .guardManage ? "cross.case.circle" : "waveform.path.ecg")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text(searchText.isEmpty ? emptyStateText : "No results for \"\(searchText)\"")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 40)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

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
        }
        .listStyle(.insetGrouped)
        .navigationTitle(accessMode.title)
        .searchable(text: $searchText, prompt: searchPrompt)
        .toolbar {
            if accessMode == .guardManage {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(AppTheme.accent)
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

    private var emptyStateText: String {
        switch accessMode {
        case .guardManage:
            return canManageRecords ? "No medical records created yet" : "Assign a block to this guard before managing medical records"
        case .wardenReadOnly:
            return "No medical status updates available"
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
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(record.medicalStatus.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: record.medicalStatus.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(record.medicalStatus.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(record.inmateName)
                    .font(.subheadline.bold())

                HStack(spacing: 6) {
                    Label(record.doctorName, systemImage: "stethoscope")
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if showsBlock {
                        Text("•")
                        Label(blockName, systemImage: "building.2")
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                StatusBadge(
                    text: record.medicalStatus.displayName,
                    color: record.medicalStatus.color,
                    small: true
                )
                Text(record.statusUpdatedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct MedicalRecordDetailView: View {
    let record: MedicalRecord
    let accessMode: MedicalRecordsAccessMode
    let blockName: String

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(record.inmateName)
                                .font(.title3.bold())
                            Text(record.doctorName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        StatusBadge(text: record.medicalStatus.displayName, color: record.medicalStatus.color)
                    }

                    Divider()

                    InfoRow(label: "Status Date", value: record.statusUpdatedAt.formatted(date: .long, time: .omitted))
                    InfoRow(label: "Created", value: record.createdAt.formatted(date: .long, time: .shortened))
                    InfoRow(label: "Updated", value: record.updatedAt.formatted(date: .long, time: .shortened))
                    InfoRow(label: "Block", value: blockName)
                }
                .padding(16)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Assignment")
                        .font(.headline)
                    InfoRow(label: "Inmate", value: record.inmateName)
                    InfoRow(label: "Doctor", value: record.doctorName)
                    InfoRow(label: "Status", value: record.medicalStatus.displayName)

                    if accessMode == .guardManage {
                        InfoRow(label: "Created By", value: record.createdByName)
                    }
                }
                .padding(16)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)

                if accessMode == .guardManage {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Medical Summary")
                            .font(.headline)
                        Text(record.conditionSummary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.primary)

                        Divider()

                        Text("Treatment Notes")
                            .font(.headline)
                        Text(record.treatmentNotes.isEmpty ? "No treatment notes added." : record.treatmentNotes)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(record.treatmentNotes.isEmpty ? .secondary : .primary)
                    }
                    .padding(16)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
            }
            .padding(16)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(accessMode == .guardManage ? "Record Detail" : "Status Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}