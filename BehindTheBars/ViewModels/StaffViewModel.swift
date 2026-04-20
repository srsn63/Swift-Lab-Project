import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class StaffViewModel: ObservableObject {

    @Published var staffList: [Staff] = []
    @Published var errorMessage: String?
    @Published var blocks: [Block] = []

    // Filters
    @Published var selectedType: StaffType?
    @Published var selectedShift: ShiftType?
    @Published var selectedBlockId: String?
    @Published var searchText: String = ""

    private var listener: ListenerRegistration?

    deinit { listener?.remove() }

    var filtered: [Staff] {
        var list = staffList
        if let type = selectedType {
            list = list.filter { $0.staffType == type.rawValue }
        }
        if let shift = selectedShift {
            list = list.filter { $0.resolvedShift == shift.rawValue }
        }
        if let blockId = selectedBlockId {
            list = list.filter {
                BlockAssignment.isAllBlocks($0.assignedBlockId) || $0.assignedBlockId == blockId
            }
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            list = list.filter { $0.fullName.lowercased().contains(q) }
        }
        return list
    }

    // MARK: - Listener

    func startListener() {
        listener?.remove()
        errorMessage = nil

        listener = FirebaseManager.shared.staffRef
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let err {
                    self.staffList = []
                    self.errorMessage = err.localizedDescription
                    return
                }
                let list = snap?.documents.compactMap(Staff.from(document:)) ?? []
                self.staffList = list
                    .filter { $0.isDeleted != true }
                    .sorted { $0.fullName < $1.fullName }
            }
    }

    func stopListener() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Blocks

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

    func blockName(for id: String) -> String {
        BlockAssignment.displayName(for: id, blocks: blocks)
    }

    // MARK: - CRUD

    func create(staff: Staff) async throws {
        var newStaff = staff
        newStaff.assignedBlockId = BlockAssignment.normalized(staff.assignedBlockId)
        try FirebaseManager.shared.staffRef.addDocument(from: newStaff)
    }

    func update(staffId: String, staff: Staff) async throws {
        let normalizedBlockId = BlockAssignment.normalized(staff.assignedBlockId)
        var payload: [String: Any] = [
            "fullName": staff.fullName,
            "staffType": staff.staffType,
            "phoneNumber": staff.phoneNumber,
            "assignedBlockId": normalizedBlockId,
            "shift": staff.shift,
            "hireDate": Timestamp(date: staff.hireDate),
            "isActive": staff.isActive,
            "notes": staff.notes,
            "updatedAt": Timestamp(date: staff.updatedAt)
        ]

        if let dutyStartAt = staff.dutyStartAt {
            payload["dutyStartAt"] = Timestamp(date: dutyStartAt)
        } else {
            payload["dutyStartAt"] = FieldValue.delete()
        }

        try await FirebaseManager.shared.staffRef
            .document(staffId)
            .updateData(payload)
    }

    func delete(staffId: String) async throws {
        try await FirebaseManager.shared.staffRef
            .document(staffId)
            .delete()
    }

    func toggleActive(staff: Staff) async throws {
        guard let id = staff.id else { return }
        try await FirebaseManager.shared.staffRef
            .document(id)
            .updateData([
                "isActive": !staff.isActive,
                "updatedAt": Timestamp(date: Date())
            ])
    }
}
