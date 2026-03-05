import Foundation
import FirebaseFirestore

final class FirebaseManager {
    static let shared = FirebaseManager()
    private init() {}

    let firestore = Firestore.firestore()

    var usersRef: CollectionReference { firestore.collection("users") }
    var inmatesRef: CollectionReference { firestore.collection("inmates") }
    var incidentsRef: CollectionReference { firestore.collection("incidents") }
    var blocksRef: CollectionReference { firestore.collection("blocks") }

    func cellsRef(blockId: String) -> CollectionReference {
        blocksRef.document(blockId).collection("cells")
    }
}
