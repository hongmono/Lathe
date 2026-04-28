import SwiftUI

struct CardView: View {
    let entry: AppEntry
    let isFocused: Bool

    private var firstLetter: String {
        let trimmed = entry.name.trimmingCharacters(in: .whitespaces)
        return String(trimmed.prefix(1)).uppercased()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 6)

            VStack(spacing: 0) {
                Text(firstLetter)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 14)
                Spacer(minLength: 0)
                Image(nsImage: entry.icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 56, height: 56)
                Spacer(minLength: 0)
            }
            .padding(.bottom, 20)
        }
        .scaleEffect(isFocused ? 1.04 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.78), value: isFocused)
    }
}
