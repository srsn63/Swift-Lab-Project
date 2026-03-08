import SwiftUI

struct ReportIncidentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = IncidentReportViewModel()

    @State private var form = IncidentFormState()
    @State private var showSelector = false

    private let penalCodes: [PenalCode] = PenalCodeLoader.load()

    var body: some View {
        NavigationStack {
            IncidentFormView(
                form: $form,
                penalCodes: penalCodes,
                onSubmit: submit,
                onSelectInmates: openSelector
            )
            .navigationTitle("Report Incident")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSelector) {
                InmateSelectionView(
                    selectedInmates: $form.selectedInmates,
                    filterBlockId: guardBlockFilter
                )
            }
            .overlay(statusOverlay, alignment: .bottom)
        }
    }

    private var guardBlockFilter: String? {
        guard let u = authVM.currentUser else { return nil }
        if u.role == "guard" { return u.assignedBlockId }
        return nil
    }

    private func openSelector() {
        if authVM.currentUser?.role == "guard" {
            if (authVM.currentUser?.assignedBlockId ?? "").isEmpty {
                vm.errorMessage = "You are not assigned to a block."
                return
            }
        }
        showSelector = true
    }

    @ViewBuilder
    private var statusOverlay: some View {
        if let err = vm.errorMessage {
            statusBanner(text: err, icon: "xmark.circle.fill", color: AppTheme.danger)
        } else if vm.submissionSuccess {
            statusBanner(text: "Incident submitted!", icon: "checkmark.circle.fill", color: AppTheme.success)
        }
    }

    private func statusBanner(text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
                .fontWeight(.medium)
        }
        .font(.subheadline)
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(color)
        .cornerRadius(12)
        .shadow(color: color.opacity(0.3), radius: 8, y: 4)
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
