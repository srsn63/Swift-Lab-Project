import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

class InmateDirectoryViewModel: ObservableObject {
    
    @Published var inmates: [Inmate] = []
    @Published var filteredInmates: [Inmate] = []
    @Published var isLoading = false
    
    private var listener: ListenerRegistration?
    
    init() {
        fetchInmates()
    }
    
    func fetchInmates() {
        isLoading = true
        
        listener = FirebaseManager.shared.inmatesRef
            .addSnapshotListener { snapshot, error in
                
                if let error = error {
                    print("Error fetching inmates:", error.localizedDescription)
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.inmates = documents.compactMap {
                    try? $0.data(as: Inmate.self)
                }
                
                self.filteredInmates = self.inmates
                self.isLoading = false
            }
    }
    
    func filterBySecurity(level: String) {
        filteredInmates = inmates.filter {
            $0.securityLevel.lowercased() == level.lowercased()
        }
    }
    
    func search(query: String) {
        if query.isEmpty {
            filteredInmates = inmates
        } else {
            filteredInmates = inmates.filter {
                $0.firstName.lowercased().contains(query.lowercased()) ||
                $0.lastName.lowercased().contains(query.lowercased())
            }
        }
    }
    
    deinit {
        listener?.remove()
    }
}
