import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class BlocksDirectoryViewModel: ObservableObject {
    @Published var blocks: [Block] = []
    @Published var errorMessage: String?

    func load() async {
        do {
            let snap = try await FirebaseManager.shared.blocksRef.getDocuments()
            var list = snap.documents.compactMap { try? $0.data(as: Block.self) }
            list = list.filter { $0.id != nil }.sorted { $0.name < $1.name }
            self.blocks = list
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
