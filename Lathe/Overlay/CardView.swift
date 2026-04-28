import SwiftUI

struct CardView: View {
    let entry: AppEntry
    let isFocused: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 6)

            Image(nsImage: entry.icon)
                .resizable()
                .interpolation(.high)
                .frame(width: 56, height: 56)
        }
        .scaleEffect(isFocused ? 1.04 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.78), value: isFocused)
    }
}
