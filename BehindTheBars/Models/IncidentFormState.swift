import Foundation

/// Holds the mutable fields while the user edits the form.
struct IncidentFormState {
    var descriptionText = ""
    var severity        = 3
    var selectedInmates: [Inmate] = []
    var selectedPenalCode = ""           // stores pc.code
}
