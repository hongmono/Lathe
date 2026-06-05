import SwiftUI
import AppKit

struct SettingsAboutDetailView: View {
    @ObservedObject var store: SettingsStore
    @ObservedObject private var updater = SparkleUpdater.shared

    var body: some View {
        VStack(alignment: .leading, spacing: SettingsViewLayout.detailGroupSpacing) {
            Label(L10n.string("settings.about.section", language: store.appLanguage),
                  systemImage: "info.circle")
                .font(.headline)
                .foregroundStyle(.primary)

            HStack(spacing: SettingsViewLayout.detailRowSpacing) {
                Text(L10n.string("settings.about.version", language: store.appLanguage))

                Text(SparkleUpdater.currentVersion())
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Toggle(L10n.string("settings.about.autoCheckUpdates", language: store.appLanguage),
                   isOn: Binding(
                    get: { updater.automaticallyChecksForUpdates },
                    set: { updater.setAutomaticallyChecksForUpdates($0) }
                   ))

            HStack(alignment: .center, spacing: SettingsViewLayout.detailRowSpacing) {
                Text(L10n.string("settings.about.updateDescription", language: store.appLanguage))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                Button {
                    updater.checkForUpdates()
                } label: {
                    Text(L10n.string("settings.about.checkNow", language: store.appLanguage))
                }
                .disabled(!updater.canCheckForUpdates)
            }
        }
    }
}

#if DEBUG
#Preview("About Detail") {
    SettingsDetailPreviewSurface {
        SettingsAboutDetailView(store: SettingsPreviewStore.makeStore(suiteName: "Lathe.SettingsAboutDetailPreview"))
    }
}
#endif
