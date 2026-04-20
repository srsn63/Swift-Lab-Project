import SwiftUI

struct InmateSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var vm: InmateSelectionViewModel
    @StateObject private var blocksVM = BlocksDirectoryViewModel()

    @Binding var selectedInmates: [Inmate]

    init(selectedInmates: Binding<[Inmate]>, filterBlockId: String? = nil) {
        self._selectedInmates = selectedInmates
        self._vm = StateObject(wrappedValue: InmateSelectionViewModel(filterBlockId: filterBlockId))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppHeroHeader(
                        title: "Select Inmates",
                        subtitle: "Build the incident roster with the same consistent inmate cards and placement cues used elsewhere in the app.",
                        icon: "person.badge.plus",
                        tint: AppTheme.accent,
                        badgeText: "\(selectedInmates.count)"
                    )
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                if let err = vm.errorMessage {
                    Section {
                        AppMessageBanner(text: err, tint: AppTheme.danger)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                if !selectedInmates.isEmpty {
                    Section {
                        AppMessageBanner(
                            text: "\(selectedInmates.count) inmate\(selectedInmates.count == 1 ? "" : "s") selected for this report.",
                            tint: AppTheme.accent,
                            icon: "checkmark.circle.fill"
                        )
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                if vm.filteredInmates.isEmpty && vm.errorMessage == nil {
                    Section {
                        AppEmptyStateCard(
                            title: "No inmates available",
                            subtitle: "The inmate roster is empty for the current filter.",
                            icon: "person.crop.rectangle.stack",
                            tint: AppTheme.accent
                        )
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    Section {
                        ForEach(vm.filteredInmates) { inmate in
                            SelectableInmateRowCard(
                                inmate: inmate,
                                blockName: blockName(for: inmate.blockId),
                                isSelected: selectedInmates.contains(where: { $0.id == inmate.id })
                            )
                            .contentShape(Rectangle())
                            .onTapGesture { toggleSelection(inmate) }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    } header: {
                        Label("Available Inmates", systemImage: "list.bullet")
                            .font(.caption.bold())
                            .foregroundColor(AppTheme.accent)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppScreenBackground())
            .searchable(text: $vm.searchText, prompt: "Search inmates")
            .navigationTitle("Select Inmates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .task {
                await blocksVM.load()
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

    private func blockName(for id: String) -> String {
        BlockAssignment.displayName(for: id, blocks: blocksVM.blocks)
    }
}

private struct SelectableInmateRowCard: View {
    let inmate: Inmate
    let blockName: String
    let isSelected: Bool

    private var tint: Color {
        isSelected ? AppTheme.accent : AppTheme.securityColor(inmate.securityLevel)
    }

    var body: some View {
        AppSurfaceCard(tint: tint, padding: 16) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(tint.opacity(0.12))
                        .frame(width: 46, height: 46)
                    Text(String(inmate.firstName.prefix(1)) + String(inmate.lastName.prefix(1)))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(tint)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(inmate.fullName)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.ink)

                    HStack(spacing: 10) {
                        Label(blockName, systemImage: "building.2")
                            .lineLimit(1)
                        Label(inmate.cellId, systemImage: "door.left.hand.closed")
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.inkMuted)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? AppTheme.accent : AppTheme.inkMuted)
            }
        }
    }
}
