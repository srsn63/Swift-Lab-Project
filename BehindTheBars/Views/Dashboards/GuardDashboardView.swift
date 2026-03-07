import SwiftUI

struct GuardDashboardView: View {

    var body: some View {

        NavigationStack {

            List {

                NavigationLink("Inmates") {
                    InmateListView()
                }

                NavigationLink("Report Incident") {
                    ReportIncidentView()
                }

                NavigationLink("Incidents") {
                    IncidentListView()
                }

            }
            .navigationTitle("Guard")
        }
    }
}
