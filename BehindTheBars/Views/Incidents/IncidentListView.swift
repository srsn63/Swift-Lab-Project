import SwiftUI

struct IncidentListView: View {
    @StateObject private var vm = IncidentListViewModel()

    var body: some View {
        List {
            if let err = vm.errorMessage {
                Text(err).foregroundStyle(.red)
            }

            ForEach(vm.incidents) { inc in
                NavigationLink {
                    IncidentDetailView(incident: inc)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Severity \(inc.severity) • \(inc.penalCode)")
                            .font(.headline)
                        Text(inc.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(inc.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Incidents")
        .onAppear { vm.start() }
    }
}
