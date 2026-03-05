import SwiftUI

struct InmateSelectionView: View {
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var vm = InmateSelectionViewModel()
    
    @Binding var selectedInmates: [Inmate]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(vm.filteredInmates) { inmate in
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text(inmate.fullName)
                                .font(.headline)
                            
                            Text("ID: \(inmate.id ?? "")")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        if selectedInmates.contains(where: { $0.id == inmate.id }) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleSelection(inmate)
                    }
                }
            }
            .searchable(text: $vm.searchText)
            .navigationTitle("Select Inmates")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleSelection(_ inmate: Inmate) {
        if let index = selectedInmates.firstIndex(where: { $0.id == inmate.id }) {
            selectedInmates.remove(at: index)
        } else {
            selectedInmates.append(inmate)
        }
    }
}
