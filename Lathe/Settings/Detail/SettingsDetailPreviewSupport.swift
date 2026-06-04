#if DEBUG
import SwiftUI

@MainActor
enum SettingsPreviewStore {
    static func makeStore(
        suiteName: String = "Lathe.SettingsPreview",
        configure: (SettingsStore) -> Void = { _ in }
    ) -> SettingsStore {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = SettingsStore(userDefaults: defaults)
        configure(store)
        return store
    }
}

@MainActor
struct SettingsDetailPreviewSurface<Content: View>: View {
    var width: CGFloat = SettingsViewLayout.detailMaxWidth + SettingsViewLayout.detailHorizontalPadding * 2
    var height: CGFloat = SettingsViewLayout.windowMinHeight
    var paddedContent = true
    @ViewBuilder var content: Content

    var body: some View {
        Group {
            if paddedContent {
                content
                    .frame(maxWidth: SettingsViewLayout.detailMaxWidth, alignment: .topLeading)
                    .padding(SettingsViewLayout.detailHorizontalPadding)
            } else {
                content
            }
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .background(.regularMaterial)
    }
}
#endif
