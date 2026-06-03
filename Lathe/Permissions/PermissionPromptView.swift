import SwiftUI

struct PermissionPromptView: View {
    let openSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label {
                Text(L10n.string("permission.title"))
                    .font(.title3)
                    .fontWeight(.semibold)
            } icon: {
                Image(systemName: "hand.raised.fill")
                    .foregroundStyle(.blue)
            }

            Text(L10n.string("permission.body"))
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                Button(L10n.string("permission.openSystemSettings")) {
                    openSettings()
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 8))
            }
        }
        .padding(22)
        .frame(width: 520)
        .background(.regularMaterial)
    }
}
