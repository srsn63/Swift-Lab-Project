import SwiftUI

struct IncidentListView: View {
    @StateObject private var vm = IncidentListViewModel()

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

            if vm.incidents.isEmpty && vm.errorMessage == nil {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.shield")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("No incidents reported")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 40)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            ForEach(vm.incidents) { inc in
                NavigationLink {
                    IncidentDetailView(incident: inc)
                } label: {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppTheme.severityColor(inc.severity))
                            .frame(width: 4, height: 50)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                StatusBadge(
                                    text: AppTheme.severityLabel(inc.severity).uppercased(),
                                    color: AppTheme.severityColor(inc.severity),
                                    small: true
                                )
                                StatusBadge(
                                    text: inc.penalCode,
                                    color: AppTheme.accent,
                                    small: true
                                )
                            }

                            Text(inc.description)
                                .font(.subheadline)
                                .lineLimit(2)

                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                Text(inc.timestamp.formatted(date: .abbreviated, time: .shortened))
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Incidents")
        .onAppear { vm.start() }
    }
}
