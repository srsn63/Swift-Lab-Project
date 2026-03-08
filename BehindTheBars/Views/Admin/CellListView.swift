import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct CellListView: View {
    let blockId: String
    let blockName: String

    @State private var cells: [Cell] = []
    @State private var error: String?

    var body: some View {
        List {
            if let error {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppTheme.danger)
                    Text(error)
                        .foregroundStyle(AppTheme.danger)
                        .font(.footnote)
                }
            }

            ForEach(cells) { c in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(occupancyColor(c).opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: "door.left.hand.closed")
                            .foregroundColor(occupancyColor(c))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(c.cellCode)
                            .font(.subheadline.bold())
                        Text("Capacity: \(c.capacity)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Text("\(c.occupancy)/\(c.capacity)")
                            .font(.subheadline.bold())
                            .foregroundColor(occupancyColor(c))

                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(UIColor.systemGray5))
                                .frame(width: 40, height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(occupancyColor(c))
                                .frame(width: c.capacity > 0 ? CGFloat(c.occupancy) / CGFloat(c.capacity) * 40 : 0, height: 6)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("\(blockName) Cells")
        .task {
            FirebaseManager.shared.cellsRef(blockId: blockId)
                .addSnapshotListener { snap, err in
                    if let err { self.error = err.localizedDescription; return }
                    self.cells = snap?.documents.compactMap { try? $0.data(as: Cell.self) } ?? []
                    self.cells.sort { $0.cellCode < $1.cellCode }
                }
        }
    }

    private func occupancyColor(_ cell: Cell) -> Color {
        if cell.occupancy >= cell.capacity { return AppTheme.danger }
        if cell.occupancy > 0 { return AppTheme.warning }
        return AppTheme.success
    }
}
