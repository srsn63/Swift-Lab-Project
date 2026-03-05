import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class InmateSelectionViewModel: ObservableObject {
    
    @Published var inmates: [Inmate] = []
    @Published var searchText = ""
    
    var filteredInmates: [Inmate] {
        if searchText.isEmpty {
            return inmates
        } else {
            return inmates.filter {
                $0.fullName.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    init() {
        fetchInmates()
    }
    
    func fetchInmates() {
        FirebaseManager.shared.inmatesRef.getDocuments { snapshot, error in
            if let documents = snapshot?.documents {
                self.inmates = documents.compactMap {
                    try? $0.data(as: Inmate.self)
                }
            }
        }
    }
}
