import SwiftUI

struct ToastView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(.black.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.top, 10)
            .padding(.horizontal, 12)
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, text: String, seconds: Double = 1.4) -> some View {
        overlay(alignment: .top) {
            if isPresented.wrappedValue {
                ToastView(text: text)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        Task {
                            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                            withAnimation { isPresented.wrappedValue = false }
                        }
                    }
            }
        }
        .animation(.easeInOut, value: isPresented.wrappedValue)
    }
}
