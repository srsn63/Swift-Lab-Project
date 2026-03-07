import SwiftUI

struct IncidentDetailView: View {
    let incident: Incident
    @StateObject private var vm = IncidentDetailViewModel()

    var body: some View {
        List {
            Section("Overview") {
                row("Severity", "\(incident.severity)")
                row("Penal code", incident.penalCode)
                row("Block", vm.blockName ?? incident.blockId)
                row("Reported by", vm.reporterDisplay ?? incident.reportedBy)
                row("Time", incident.timestamp.formatted(date: .abbreviated, time: .shortened))
            }

            Section("Description") {
                Text(incident.description)
            }

            Section("Involved inmates") {
                if let err = vm.errorMessage {
                    Text(err).foregroundStyle(.red)
                }

                if vm.inmates.isEmpty {
                    ForEach(incident.involvedInmates, id: \.self) { id in Text(id) }
                } else {
                    ForEach(vm.inmates) { i in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(i.fullName).font(.headline)
                            Text("Cell: \(i.cellId) • Security: \(i.securityLevel)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Incident")
        .task { await vm.loadAll(for: incident) }
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k)
            Spacer()
            Text(v).foregroundStyle(.secondary)
        }
    }
}
