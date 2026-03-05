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
            VStack(alignment: .leading, spacing: 16) {

                Group {
                    Text("Report Incident")
                        .font(.title2).fontWeight(.semibold)

                    TextField("Description", text: $form.descriptionText)
                        .textFieldStyle(.roundedBorder)

                    Stepper("Severity: \(form.severity)",
                            value: $form.severity,
                            in: 1...5)
                }

                Divider()

                Button("Select inmates", action: onSelectInmates)

                if form.selectedInmates.isEmpty {
                    Text("No inmates selected")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(form.selectedInmates) { inmate in
                        Text(inmate.fullName).foregroundStyle(.blue)
                    }
                }

                Divider()

                Menu {
                    Button("Clear selection") { form.selectedPenalCode = "" }
                    ForEach(penalCodes, id: \.code) { pc in
                        Button("\(pc.code) – \(pc.title)") {
                            form.selectedPenalCode = pc.code
                        }
                    }
                } label: {
                    HStack {
                        Text(form.selectedPenalCode.isEmpty
                             ? "Select penal code"
                             : form.selectedPenalCode)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button("Submit Incident", action: onSubmit)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
        }
    }
}
