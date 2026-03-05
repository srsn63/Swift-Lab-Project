import SwiftUI

struct ReportIncidentView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = IncidentReportViewModel()

    @State private var form = IncidentFormState()
    @State private var showSelector = false

    // Load from local JSON once; no dependency on JSONParserService singleton names
    private let penalCodes: [PenalCode] = PenalCodeLoader.load()

    var body: some View {
        NavigationStack {
            IncidentFormView(
                form: $form,
                penalCodes: penalCodes,
                onSubmit: submit,
                onSelectInmates: { showSelector = true }
            )
            .navigationTitle("Incident")
            .sheet(isPresented: $showSelector) {
                InmateSelectionView(selectedInmates: $form.selectedInmates)
            }
            .overlay(statusOverlay, alignment: .bottom)
        }
    }

    @ViewBuilder
    private var statusOverlay: some View {
        if let err = vm.errorMessage {
            banner(text: err, color: .red)
        } else if vm.submissionSuccess {
            banner(text: "Incident submitted!", color: .green)
        }
    }

    private func banner(text: String, color: Color) -> some View {
        Text(text)
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(color.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.bottom, 20)
    }

    private func submit() {
        guard let user = authVM.currentUser else {
            vm.errorMessage = "No user loaded."
            return
        }

        let desc = form.descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        if desc.isEmpty { vm.errorMessage = "Description required."; return }
        if form.selectedInmates.isEmpty { vm.errorMessage = "Select inmates."; return }
        if form.selectedPenalCode.isEmpty { vm.errorMessage = "Select penal code."; return }

        Task {
            await vm.submitIncident(
                currentUser: user,
                description: desc,
                severity: form.severity,
                selectedInmates: form.selectedInmates,
                penalCode: form.selectedPenalCode
            )
        }
    }
}
