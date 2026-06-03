import SwiftUI

struct SettingsGeneralDetailView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: SettingsViewLayout.detailGroupSpacing) {
            Label(L10n.string("settings.appearance.section", language: store.appLanguage),
                  systemImage: "paintbrush")
                .font(.headline)
                .foregroundStyle(.primary)
            
            HStack(spacing: SettingsViewLayout.detailRowSpacing) {
                Text(L10n.string("settings.appearance.language", language: store.appLanguage))

                Picker("", selection: $store.appLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.label(language: store.appLanguage)).tag(language)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }
            
            HStack(spacing: SettingsViewLayout.detailRowSpacing) {
                Text(L10n.string("settings.appearance.theme", language: store.appLanguage))

                Picker("", selection: $store.appearance) {
                    ForEach(Appearance.allCases) { appearance in
                        Text(appearance.label(language: store.appLanguage)).tag(appearance)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }
            
            Spacer().frame(height: SettingsViewLayout.detailSectionBreakHeight)
            
            Label(L10n.string("settings.general.section", language: store.appLanguage),
                  systemImage: "power")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Toggle(L10n.string("settings.general.launchAtLogin", language: store.appLanguage),
                   isOn: $store.launchAtLogin)
            
            Text(L10n.string("settings.general.launchAtLogin.description", language: store.appLanguage))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

#if DEBUG
#Preview("General Detail") {
    SettingsDetailPreviewSurface {
        SettingsGeneralDetailView(
            store: SettingsPreviewStore.makeStore(suiteName: "Lathe.SettingsGeneralDetailPreview") { store in
                store.appearance = .dark
            }
        )
    }
}
#endif
