import SwiftUI

struct PenalCodeReferenceView: View {
    
    @Environment(\.presentationMode) var presentation
    @Binding var selectedCode: PenalCode?
    
    let codes = JSONParserService.loadPenalCodes()
    
    var body: some View {
        NavigationView {
            List(codes) { code in
                VStack(alignment: .leading) {
                    Text(code.code)
                        .bold()
                    Text(code.title)
                    Text("Severity: \(code.severityLevel)")
                        .font(.caption)
                }
                .onTapGesture {
                    selectedCode = code
                    presentation.wrappedValue.dismiss()
                }
            }
            .navigationTitle("Penal Codes")
        }
    }
}
