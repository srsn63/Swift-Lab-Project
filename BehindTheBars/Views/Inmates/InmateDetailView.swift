import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct InmateDetailView: View {
    let inmate: Inmate
    @State private var blockName: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.securityColor(inmate.securityLevel).opacity(0.15))
                            .frame(width: 80, height: 80)
                        Text(String(inmate.firstName.prefix(1)) + String(inmate.lastName.prefix(1)))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppTheme.securityColor(inmate.securityLevel))
                    }

                    Text(inmate.fullName)
                        .font(.title2.bold())

                    StatusBadge(
                        text: inmate.securityLevel.uppercased(),
                        color: AppTheme.securityColor(inmate.securityLevel)
                    )

                    if inmate.isSolitary {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                            Text("Solitary Confinement")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.danger)
                        .cornerRadius(8)
                    }
                }
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemGroupedBackground))

                // Info sections
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Placement", systemImage: "building.2")
                            .font(.caption.bold())
                            .foregroundColor(AppTheme.accent)
                        Divider()
                        InfoRow(label: "Block", value: blockName ?? inmate.blockId)
                        InfoRow(label: "Cell", value: inmate.cellId)
                    }
                    .padding(16)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(14)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Sentence", systemImage: "calendar")
                            .font(.caption.bold())
                            .foregroundColor(AppTheme.accent)
                        Divider()
                        InfoRow(label: "Admitted", value: inmate.admissionDate.formatted(date: .abbreviated, time: .omitted))
                        InfoRow(label: "Duration", value: "\(inmate.sentenceMonths) months")
                        InfoRow(label: "Release Date", value: inmate.releaseDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    .padding(16)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(14)
                }
                .padding(16)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if blockName == nil, !inmate.blockId.isEmpty {
                 // Try to fetch block name
                 do {
                     let doc = try await FirebaseManager.shared.blocksRef.document(inmate.blockId).getDocument()
                     if let block = try? doc.data(as: Block.self) {
                         self.blockName = block.name
                     }
                 } catch {
                     print("Error fetching block name: \(error)")
                 }
            }
        }
    }
}
