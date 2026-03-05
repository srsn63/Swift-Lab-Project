import SwiftUI

struct InmateDetailView: View {
    
    let inmate: Inmate
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("\(inmate.firstName) \(inmate.lastName)")
                .font(.largeTitle)
                .bold()
            
            Text("Cell: \(inmate.cellId)")
            
            Text("Security Level: \(inmate.securityLevel)")
            
            Text("Admitted: \(inmate.admissionDate.formatted())")
            
            if inmate.isSolitary {
                Text("In Solitary Confinement")
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Details")
    }
}
