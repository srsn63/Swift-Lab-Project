import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct InmateDetailView: View {
    let inmate: Inmate
    let initialBlockName: String?

    @State private var blockName: String?

    init(inmate: Inmate, initialBlockName: String? = nil) {
        self.inmate = inmate
        self.initialBlockName = initialBlockName
    }

    private var securityColor: Color {
        AppTheme.securityColor(inmate.securityLevel)
    }

    var body: some View {
        ZStack {
            AppScreenBackground()

            ScrollView {
                VStack(spacing: 18) {
                    AppHeroHeader(
                        title: inmate.fullName,
                        subtitle: "\(resolvedBlockName) / Cell \(inmate.cellId)",
                        icon: "person.crop.rectangle.stack.fill",
                        tint: securityColor,
                        badgeText: inmate.securityLevel.uppercased()
                    )

                    if inmate.isSolitary {
                        AppMessageBanner(
                            text: "This inmate is currently marked for solitary confinement.",
                            tint: AppTheme.danger,
                            icon: "lock.fill"
                        )
                    }

                    AppSurfaceCard(tint: securityColor) {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Placement", systemImage: "building.2")
                                .font(.caption.bold())
                                .foregroundColor(securityColor)

                            InfoRow(label: "Block", value: resolvedBlockName)
                            InfoRow(label: "Cell", value: inmate.cellId)
                            InfoRow(label: "Security Level", value: inmate.securityLevel.capitalized)
                            InfoRow(label: "Custody", value: inmate.isSolitary ? "Solitary Confinement" : "Standard Housing")
                        }
                    }

                    AppSurfaceCard(tint: AppTheme.accent) {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Sentence Timeline", systemImage: "calendar.badge.clock")
                                .font(.caption.bold())
                                .foregroundColor(AppTheme.accent)

                            InfoRow(label: "Admitted", value: inmate.admissionDate.formatted(date: .long, time: .omitted))
                            InfoRow(label: "Sentence Length", value: "\(inmate.sentenceMonths) months")
                            InfoRow(label: "Release Date", value: inmate.releaseDate.formatted(date: .long, time: .omitted))
                            InfoRow(label: "Time Remaining", value: remainingTimeText)
                        }
                    }

                    AppSurfaceCard(tint: inmate.isSolitary ? AppTheme.danger : AppTheme.success) {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Status", systemImage: inmate.isSolitary ? "lock.shield.fill" : "checkmark.shield.fill")
                                .font(.caption.bold())
                                .foregroundColor(inmate.isSolitary ? AppTheme.danger : AppTheme.success)

                            Text(inmateStatusSummary)
                                .font(.body)
                                .foregroundStyle(AppTheme.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Inmate Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if blockName == nil {
                blockName = initialBlockName
            }

            if blockName == nil, !inmate.blockId.isEmpty {
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

    private var resolvedBlockName: String {
        blockName ?? inmate.blockId
    }

    private var remainingTimeText: String {
        let now = Calendar.current.startOfDay(for: Date())
        let release = Calendar.current.startOfDay(for: inmate.releaseDate)

        if release < now {
            return "Release date reached"
        }

        let components = Calendar.current.dateComponents([.month, .day], from: now, to: release)
        let months = max(components.month ?? 0, 0)
        let days = max(components.day ?? 0, 0)
        return "\(months) months, \(days) days"
    }

    private var inmateStatusSummary: String {
        if inmate.isSolitary {
            return "This inmate is under solitary confinement and should be reviewed with elevated custody awareness."
        }

        return "This inmate is housed in the standard population with a \(inmate.securityLevel.lowercased()) security classification."
    }
}
