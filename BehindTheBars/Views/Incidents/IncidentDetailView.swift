import SwiftUI

struct IncidentDetailView: View {
    let incident: Incident
    @StateObject private var vm = IncidentDetailViewModel()

    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.severityColor(incident.severity).opacity(0.15))
                                .frame(width: 60, height: 60)
                            Text("\(incident.severity)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(AppTheme.severityColor(incident.severity))
                        }
                        Text(AppTheme.severityLabel(incident.severity))
                            .font(.headline)
                            .foregroundColor(AppTheme.severityColor(incident.severity))
                        Text("Severity Level")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    Spacer()
                }
            }

            Section {
                detailRow(icon: "number", label: "Penal Code", value: incident.penalCode)
                detailRow(icon: "building.2", label: "Block", value: vm.blockName ?? incident.blockId)
                detailRow(icon: "person.badge.shield.checkmark", label: "Reported By", value: vm.reporterDisplay ?? incident.reportedBy)
                detailRow(icon: "clock", label: "Time", value: incident.timestamp.formatted(date: .abbreviated, time: .shortened))
            } header: {
                Label("Overview", systemImage: "info.circle")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }

            Section {
                Text(incident.description)
                    .font(.body)
                    .padding(.vertical, 4)
            } header: {
                Label("Description", systemImage: "doc.text")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }

            Section {
                if let err = vm.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppTheme.danger)
                        Text(err)
                            .foregroundStyle(AppTheme.danger)
                            .font(.footnote)
                    }
                }

                if vm.inmates.isEmpty {
                    ForEach(incident.involvedInmates, id: \.self) { id in
                        Label(id, systemImage: "person")
                            .foregroundColor(.secondary)
                    }
                } else {
                    ForEach(vm.inmates) { i in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.securityColor(i.securityLevel).opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Text(String(i.firstName.prefix(1)))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.securityColor(i.securityLevel))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(i.fullName).font(.subheadline.bold())
                                Text("Cell: \(i.cellId) • \(i.securityLevel)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            } header: {
                Label("Involved Inmates (\(incident.involvedInmates.count))", systemImage: "person.2")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accent)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Incident")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.loadAll(for: incident) }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.accent)
                .frame(width: 20)
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}
