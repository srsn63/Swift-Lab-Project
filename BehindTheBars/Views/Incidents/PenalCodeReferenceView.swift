import SwiftUI

struct PenalCodeReferenceView: View {
    
    @Environment(\.presentationMode) var presentation
    @Binding var selectedCode: PenalCode?
    
    let codes = JSONParserService.loadPenalCodes()
    
    var body: some View {
        NavigationView {
            List(codes) { code in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.severityColor(code.severityLevel).opacity(0.12))
                            .frame(width: 40, height: 40)
                        Text("\(code.severityLevel)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.severityColor(code.severityLevel))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(code.code)
                            .font(.subheadline.bold())
                        Text(code.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    StatusBadge(
                        text: "Sev \(code.severityLevel)",
                        color: AppTheme.severityColor(code.severityLevel),
                        small: true
                    )
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedCode = code
                    presentation.wrappedValue.dismiss()
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Penal Codes")
        }
    }
}
