import SwiftUI
import AppKit

struct SettingsAboutDetailView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: SettingsViewLayout.detailGroupSpacing) {
            Label(L10n.string("settings.about.section", language: store.appLanguage),
                  systemImage: "info.circle")
                .font(.headline)
                .foregroundStyle(.primary)

            HStack(spacing: SettingsViewLayout.detailRowSpacing) {
                Text(L10n.string("settings.about.version", language: store.appLanguage))

                Text(UpdateChecker.currentVersion())
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Toggle(L10n.string("settings.about.autoCheckUpdates", language: store.appLanguage),
                   isOn: $store.autoCheckUpdates)

            HStack(alignment: .center, spacing: SettingsViewLayout.detailRowSpacing) {
                updateStatusView

                if let update = store.availableUpdate {
                    Button(String(
                        format: L10n.string("settings.about.downloadFormat", language: store.appLanguage),
                        update.tagName
                    )) {
                        NSWorkspace.shared.open(update.htmlURL)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        Task { await store.checkForUpdates() }
                    } label: {
                        if store.isCheckingForUpdates {
                            ProgressView().controlSize(.small)
                        } else {
                            Text(L10n.string("settings.about.checkNow", language: store.appLanguage))
                        }
                    }
                    .disabled(store.isCheckingForUpdates)
                }
            }
        }
    }

    @ViewBuilder
    private var updateStatusView: some View {
        if let err = store.updateCheckError {
            Text(err)
                .font(.system(size: 11))
                .foregroundStyle(.red)
        } else if store.availableUpdate != nil {
            Text(L10n.string("settings.about.updateAvailable", language: store.appLanguage))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        } else if let last = store.lastUpdateCheck {
            Text(String(
                format: L10n.string("settings.about.upToDateFormat", language: store.appLanguage),
                locale: Locale.current,
                arguments: [last.formatted(.relative(presentation: .named))]
            ))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        } else {
            Text(L10n.string("settings.about.updateDescription", language: store.appLanguage))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}

#if DEBUG
#Preview("About Detail") {
    SettingsDetailPreviewSurface {
        SettingsAboutDetailView(
            store: SettingsPreviewStore.makeStore(suiteName: "Lathe.SettingsAboutDetailPreview") { store in
                store.lastUpdateCheck = Date()
            }
        )
    }
}
#endif
