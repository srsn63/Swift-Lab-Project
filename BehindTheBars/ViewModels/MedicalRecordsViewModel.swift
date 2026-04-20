import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

enum MedicalRecordsError: LocalizedError {
    case readOnlyRole
    case missingGuardBlock
    case invalidBlockAccess
    case incompleteRecord

    var errorDescription: String? {
        switch self {
        case .readOnlyRole:
            return "Only guards can manage medical records."
        case .missingGuardBlock:
            return "You are not assigned to a block."
        case .invalidBlockAccess:
            return "You can only manage medical records for inmates in your assigned block."
        case .incompleteRecord:
            return "Select an inmate, assign a doctor, and enter a medical summary."
        }
    }
}

@MainActor
final class MedicalRecordsViewModel: ObservableObject {
    @Published var records: [MedicalRecord] = []
    @Published var availableInmates: [Inmate] = []
    @Published var availableDoctors: [Staff] = []
    @Published var blocks: [Block] = []
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?

    deinit { listener?.remove() }

    func inmateSelectionMessage(for user: User) -> String? {
        guard user.role == "guard" else { return nil }

        guard let blockId = user.assignedBlockId, !blockId.isEmpty else {
            return "You need a block assignment before creating a medical record."
        }

        guard availableInmates.isEmpty else { return nil }
        return "No inmates are available in \(blockName(for: blockId))."
    }

    func doctorSelectionMessage(for user: User) -> String? {
        guard user.role == "guard" else { return nil }

        guard user.assignedBlockId?.isEmpty == false else {
            return "You need a block assignment before selecting a doctor."
        }

        guard availableDoctors.isEmpty else { return nil }
        return "No active doctors are available in the system."
    }

    func doctorLabel(for doctor: Staff) -> String {
        let blockLabel = blockName(for: doctor.assignedBlockId)
        return doctor.assignedBlockId.isEmpty ? "\(doctor.fullName) - Unassigned" : "\(doctor.fullName) - \(blockLabel)"
    }

    func startListener(for user: User) {
        listener?.remove()
        errorMessage = nil

        var query: Query = FirebaseManager.shared.medicalRecordsRef

        if user.role == "guard" {
            guard let blockId = user.assignedBlockId, !blockId.isEmpty else {
                records = []
                errorMessage = MedicalRecordsError.missingGuardBlock.errorDescription
                return
            }
            query = query.whereField("blockId", isEqualTo: blockId)
        }

        listener = query.addSnapshotListener { [weak self] snap, err in
            guard let self else { return }

            if let err {
                self.records = []
                self.errorMessage = err.localizedDescription
                return
            }

            let list = snap?.documents.compactMap { try? $0.data(as: MedicalRecord.self) } ?? []
            self.records = list.sorted { lhs, rhs in
                if lhs.statusUpdatedAt == rhs.statusUpdatedAt {
                    return lhs.updatedAt > rhs.updatedAt
                }
                return lhs.statusUpdatedAt > rhs.statusUpdatedAt
            }
        }
    }

    func stopListener() {
        listener?.remove()
        listener = nil
    }

    func loadBlocks() async {
        do {
            let snap = try await FirebaseManager.shared.blocksRef.getDocuments()
            var list = snap.documents.compactMap { try? $0.data(as: Block.self) }
            list = list.filter { $0.id != nil }.sorted { $0.name < $1.name }
            self.blocks = list
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func loadEditorData(for user: User) async {
        errorMessage = nil

        guard user.role == "guard" else {
            availableInmates = []
            availableDoctors = []
            return
        }

        guard let blockId = user.assignedBlockId, !blockId.isEmpty else {
            availableInmates = []
            availableDoctors = []
            errorMessage = MedicalRecordsError.missingGuardBlock.errorDescription
            return
        }

        do {
            let inmateSnapshot = try await FirebaseManager.shared.inmatesRef
                .whereField("blockId", isEqualTo: blockId)
                .getDocuments()
            let doctorSnapshot = try await FirebaseManager.shared.staffRef
                .whereField("staffType", isEqualTo: StaffType.doctor.rawValue)
                .getDocuments()

            let inmates = inmateSnapshot.documents.compactMap { try? $0.data(as: Inmate.self) }
            let doctors = doctorSnapshot.documents.compactMap { try? $0.data(as: Staff.self) }

            self.availableInmates = inmates.sorted { $0.fullName < $1.fullName }
            self.availableDoctors = doctors
                .filter(\.isActive)
                .sorted { lhs, rhs in
                    if lhs.fullName == rhs.fullName {
                        return lhs.assignedBlockId < rhs.assignedBlockId
                    }
                    return lhs.fullName < rhs.fullName
                }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func create(record: MedicalRecord, currentUser: User) async throws {
        try validateWritable(record: record, currentUser: currentUser)
        try FirebaseManager.shared.medicalRecordsRef.addDocument(from: record)
    }

    func update(recordId: String, record: MedicalRecord, currentUser: User) async throws {
        try validateWritable(record: record, currentUser: currentUser)
        try FirebaseManager.shared.medicalRecordsRef
            .document(recordId)
            .setData(from: record, merge: true)
    }

    func delete(record: MedicalRecord, currentUser: User) async throws {
        try validateWritable(record: record, currentUser: currentUser)
        guard let recordId = record.id else { return }
        try await FirebaseManager.shared.medicalRecordsRef
            .document(recordId)
            .delete()
    }

    func blockName(for blockId: String) -> String {
        if blockId.isEmpty { return "Unassigned" }
        return blocks.first(where: { $0.id == blockId })?.name ?? blockId
    }

    private func validateWritable(record: MedicalRecord, currentUser: User) throws {
        guard currentUser.role == "guard" else {
            throw MedicalRecordsError.readOnlyRole
        }

        guard let assignedBlockId = currentUser.assignedBlockId, !assignedBlockId.isEmpty else {
            throw MedicalRecordsError.missingGuardBlock
        }

        guard record.blockId == assignedBlockId else {
            throw MedicalRecordsError.invalidBlockAccess
        }

        let trimmedSummary = record.conditionSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !record.inmateId.isEmpty,
              !record.doctorId.isEmpty,
              !trimmedSummary.isEmpty else {
            throw MedicalRecordsError.incompleteRecord
        }
    }
}
