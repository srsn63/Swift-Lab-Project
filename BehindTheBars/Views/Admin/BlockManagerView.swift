import SwiftUI

struct BlockManagerView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = BlockAdminViewModel()

    @State private var newBlockName = ""

    var body: some View {
        List {
            if let err = vm.errorMessage {
                Text(err).foregroundStyle(.red)
            }

            Section("Create Block") {
                HStack {
                    TextField("Block name (e.g. A)", text: $newBlockName)
                        .textInputAutocapitalization(.characters)

                    Button("Create") {
                        Task {
                            guard let uid = authVM.currentUser?.uid else { return }
                            do {
                                try await vm.createBlock(name: newBlockName, createdBy: uid)
                                newBlockName = ""
                            } catch {
                                vm.errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Section("Blocks") {
                ForEach(vm.blocks) { b in
                    if let blockId = b.id {
                        NavigationLink(b.name) {
                            CellListView(blockId: blockId, blockName: b.name)
                        }
                    } else {
                        Text(b.name)
                    }
                }
            }
        }
        .navigationTitle("Blocks")
        .onAppear { vm.startListener() }
    }
}
