import SwiftUI

struct WardenDashboardView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Inmates") { InmateListView() }
                NavigationLink("Guards") { GuardListView() }
                NavigationLink("Report Incident") { ReportIncidentView() }
            }
            .navigationTitle("Warden")
        }
    }
}
