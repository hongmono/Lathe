import SwiftUI

struct CardView: View {
    let entry: AppEntry
    let isFocused: Bool
    let showsName: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isFocused ? .regularMaterial : .thinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(isFocused ? 0.42 : 0.24), lineWidth: 0.8)
                }
                .shadow(color: .black.opacity(isFocused ? 0.28 : 0.16),
                        radius: isFocused ? 22 : 12,
                        x: 0,
                        y: isFocused ? 12 : 6)

            VStack(spacing: showsName ? 10 : 0) {
                Image(nsImage: entry.icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: isFocused ? 60 : 54, height: isFocused ? 60 : 54)
                    .shadow(color: .black.opacity(isFocused ? 0.16 : 0.08), radius: 4, x: 0, y: 2)

                if showsName {
                    Text(entry.name)
                        .font(.system(size: isFocused ? 13 : 12, weight: isFocused ? .semibold : .medium))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(isFocused ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12)
                }
            }
        }
    }
}
