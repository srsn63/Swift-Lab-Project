import SwiftUI

struct InmateSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var vm: InmateSelectionViewModel

    @Binding var selectedInmates: [Inmate]

    init(selectedInmates: Binding<[Inmate]>, filterBlockId: String? = nil) {
        self._selectedInmates = selectedInmates
        self._vm = StateObject(wrappedValue: InmateSelectionViewModel(filterBlockId: filterBlockId))
    }

    var body: some View {
        NavigationStack {
            List {
                if let err = vm.errorMessage {
                    Text(err).foregroundStyle(.red)
                }

                ForEach(vm.filteredInmates) { inmate in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(inmate.fullName).font(.headline)
                            Text("Block: \(inmate.blockId) • Cell: \(inmate.cellId)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selectedInmates.contains(where: { $0.id == inmate.id }) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { toggleSelection(inmate) }
                }
            }
            .searchable(text: $vm.searchText)
            .navigationTitle("Select Inmates")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
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
