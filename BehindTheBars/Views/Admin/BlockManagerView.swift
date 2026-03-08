import SwiftUI

struct BlockManagerView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = BlockAdminViewModel()

    @State private var newBlockName = ""

    var body: some View {
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

            Section {
                HStack(spacing: 12) {
                    Image(systemName: "plus.square.fill")
                        .foregroundColor(AppTheme.accent)
                        .font(.title3)
                    TextField("Block name (e.g. A)", text: $newBlockName)
                        .textInputAutocapitalization(.characters)

                    Button {
                        Task {
                            guard let uid = authVM.currentUser?.uid else { return }
                            do {
                                try await vm.createBlock(name: newBlockName, createdBy: uid)
                                newBlockName = ""
                            } catch {
                                vm.errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        Text("Create")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppTheme.accent)
                            .cornerRadius(8)
                    }
                    .disabled(newBlockName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } header: {
                Label("Create Block", systemImage: "building.2")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }

            Section {
                if vm.blocks.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "building.2")
                                .font(.title)
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No blocks yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 20)
                        Spacer()
                    }
                } else {
                    ForEach(vm.blocks) { b in
                        if let blockId = b.id {
                            NavigationLink {
                                CellListView(blockId: blockId, blockName: b.name)
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(AppTheme.accent.opacity(0.12))
                                            .frame(width: 40, height: 40)
                                        Text(b.name)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(AppTheme.accent)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Block \(b.name)")
                                            .font(.subheadline.bold())
                                        Text("Tap to view cells")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        } else {
                            Text(b.name)
                        }
                    }
                }
            } header: {
                Label("Blocks", systemImage: "building.2.fill")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Blocks")
        .onAppear { vm.startListener() }
    }
}
