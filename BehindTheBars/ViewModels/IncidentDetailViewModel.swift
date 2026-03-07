import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class IncidentDetailViewModel: ObservableObject {
    @Published var blockName: String?
    @Published var reporterDisplay: String?
    @Published var inmates: [Inmate] = []
    @Published var errorMessage: String?

    func loadAll(for incident: Incident) async {
        errorMessage = nil
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadBlockName(blockId: incident.blockId) }
            group.addTask { await self.loadReporter(uid: incident.reportedBy) }
            group.addTask { await self.loadInmates(ids: incident.involvedInmates) }
        }
    }

    private func loadBlockName(blockId: String) async {
        do {
            let snap = try await FirebaseManager.shared.blocksRef.document(blockId).getDocument()
            if let block = try? snap.data(as: Block.self) {
                self.blockName = block.name
            } else {
                self.blockName = blockId
            }
        } catch {
            self.blockName = blockId
        }
    }

    private func loadReporter(uid: String) async {
        do {
            let snap = try await FirebaseManager.shared.usersRef.document(uid).getDocument()
            if let u = try? snap.data(as: User.self) {
                let name = (u.fullName?.isEmpty == false) ? u.fullName! : u.email
                self.reporterDisplay = "\(name) (\(u.role))"
            } else {
                self.reporterDisplay = uid
            }
        } catch {
            self.reporterDisplay = uid
        }
    }

    private func loadInmates(ids: [String]) async {
        inmates = []
        let ids = Array(Set(ids)).filter { !$0.isEmpty }
        guard !ids.isEmpty else { return }

        // Firestore `in` max 10
        let chunks: [[String]] = stride(from: 0, to: ids.count, by: 10).map {
            Array(ids[$0..<min($0 + 10, ids.count)])
        }

        do {
            var result: [Inmate] = []
            for chunk in chunks {
                let snap = try await FirebaseManager.shared.inmatesRef
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()

                result.append(contentsOf: snap.documents.compactMap { try? $0.data(as: Inmate.self) })
            }
            inmates = result.sorted { $0.fullName < $1.fullName }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
