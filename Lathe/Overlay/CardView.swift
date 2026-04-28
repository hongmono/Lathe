import SwiftUI

struct CardView: View {
    let entry: AppEntry
    let isFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(nsImage: entry.icon)
                .resizable()
                .interpolation(.high)
                .frame(width: 80, height: 80)
            if isFocused {
                Text(entry.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: 160)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(isFocused ? 1 : 0.6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(isFocused ? 0.9 : 0), lineWidth: 2)
        )
    }
}
