import SwiftUI

struct GuardDashboardView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Inmates") { InmateListView() }
            }
            .navigationTitle("Guard")
        }
    }
}
