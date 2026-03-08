import SwiftUI

struct IncidentFormView: View {

    @Binding var form: IncidentFormState          // data the parent owns
    let penalCodes: [PenalCode]                   // injected list

    /// Emits `true` when “Submit” is tapped.
    let onSubmit: () -> Void
    /// Emits whenever user requests inmate selection.
    let onSelectInmates: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Description section
                VStack(alignment: .leading, spacing: 10) {
                    Label("Description", systemImage: "doc.text")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.accent)

                    TextField("Describe the incident…", text: $form.descriptionText, axis: .vertical)
                        .lineLimit(3...6)
                        .padding(14)
                        .background(Color(UIColor.tertiarySystemFill))
                        .cornerRadius(12)
                }

                // Severity section
                VStack(alignment: .leading, spacing: 10) {
                    Label("Severity Level", systemImage: "gauge.medium")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.accent)

                    HStack(spacing: 0) {
                        ForEach(1...5, id: \.self) { level in
                            Button {
                                form.severity = level
                            } label: {
                                VStack(spacing: 4) {
                                    Text("\(level)")
                                        .font(.system(size: 16, weight: .bold))
                                    Text(AppTheme.severityLabel(level))
                                        .font(.system(size: 9))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    form.severity == level
                                    ? AppTheme.severityColor(level).opacity(0.15)
                                    : Color(UIColor.tertiarySystemFill)
                                )
                                .foregroundColor(
                                    form.severity == level
                                    ? AppTheme.severityColor(level)
                                    : .secondary
                                )
                            }
                        }
                    }
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(UIColor.separator), lineWidth: 0.5)
                    )
                }

                Divider()

                // Inmates section
                VStack(alignment: .leading, spacing: 10) {
                    Label("Involved Inmates", systemImage: "person.2")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.accent)

                    Button(action: onSelectInmates) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Select Inmates")
                            Spacer()
                            if !form.selectedInmates.isEmpty {
                                Text("\(form.selectedInmates.count)")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(AppTheme.accent)
                                    .cornerRadius(10)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .padding(14)
                        .background(Color(UIColor.tertiarySystemFill))
                        .cornerRadius(12)
                        .foregroundColor(.primary)
                    }

                    if form.selectedInmates.isEmpty {
                        Text("No inmates selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)
                    } else {
                        ForEach(form.selectedInmates) { inmate in
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.accent.opacity(0.12))
                                        .frame(width: 30, height: 30)
                                    Text(String(inmate.firstName.prefix(1)))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(AppTheme.accent)
                                }
                                Text(inmate.fullName)
                                    .font(.subheadline)
                            }
                        }
                    }
                }

                Divider()

                // Penal Code section
                VStack(alignment: .leading, spacing: 10) {
                    Label("Penal Code", systemImage: "book.closed")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.accent)

                    Menu {
                        Button("Clear selection") { form.selectedPenalCode = "" }
                        ForEach(penalCodes, id: \.code) { pc in
                            Button("\(pc.code) – \(pc.title)") {
                                form.selectedPenalCode = pc.code
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: form.selectedPenalCode.isEmpty ? "doc.questionmark" : "checkmark.seal")
                                .foregroundColor(form.selectedPenalCode.isEmpty ? .secondary : AppTheme.accent)
                            Text(form.selectedPenalCode.isEmpty
                                 ? "Select penal code"
                                 : form.selectedPenalCode)
                                .foregroundColor(form.selectedPenalCode.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .background(Color(UIColor.tertiarySystemFill))
                        .cornerRadius(12)
                    }
                }

                // Submit button
                Button(action: onSubmit) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Submit Incident Report")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.danger)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}
