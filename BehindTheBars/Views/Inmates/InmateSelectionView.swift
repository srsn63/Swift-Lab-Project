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
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppTheme.danger)
                        Text(err)
                            .foregroundStyle(AppTheme.danger)
                            .font(.footnote)
                    }
                }

                if !selectedInmates.isEmpty {
                    Section {
                        Text("\(selectedInmates.count) inmate\(selectedInmates.count == 1 ? "" : "s") selected")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.accent)
                    }
                }

                ForEach(vm.filteredInmates) { inmate in
                    let isSelected = selectedInmates.contains(where: { $0.id == inmate.id })

                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(isSelected ? AppTheme.accent.opacity(0.15) : Color(UIColor.tertiarySystemFill))
                                .frame(width: 40, height: 40)
                            Text(String(inmate.firstName.prefix(1)))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(isSelected ? AppTheme.accent : .secondary)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(inmate.fullName)
                                .font(.subheadline.bold())
                            HStack(spacing: 4) {
                                Text("Block: \(inmate.blockId)")
                                Text("•")
                                Text("Cell: \(inmate.cellId)")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundColor(isSelected ? AppTheme.accent : Color(UIColor.tertiaryLabel))
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    .onTapGesture { toggleSelection(inmate) }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $vm.searchText, prompt: "Search inmates")
            .navigationTitle("Select Inmates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
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
