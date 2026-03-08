import SwiftUI

struct ToastView: View {
    let text: String
    var isError: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                .font(.body.weight(.semibold))
            Text(text)
                .font(.subheadline.weight(.medium))
        }
        .foregroundStyle(.white)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            (isError ? AppTheme.danger : AppTheme.primary)
                .opacity(0.92)
        )
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
        .padding(.top, 10)
        .padding(.horizontal, 12)
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, text: String, isError: Bool = false, seconds: Double = 1.4) -> some View {
        overlay(alignment: .top) {
            if isPresented.wrappedValue {
                ToastView(text: text, isError: isError)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        Task {
                            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                            withAnimation { isPresented.wrappedValue = false }
                        }
                    }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isPresented.wrappedValue)
    }
}
