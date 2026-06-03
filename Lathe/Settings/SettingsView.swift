import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.string("settings.appearance.section")) {
                    Picker(L10n.string("settings.appearance.language"), selection: $store.appLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.label).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker(L10n.string("settings.appearance.theme"), selection: $store.appearance) {
                        ForEach(Appearance.allCases) { a in
                            Text(a.label).tag(a)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(L10n.string("settings.carousel.section")) {
                    Picker(L10n.string("settings.carousel.layout"), selection: $store.layoutStyle) {
                        ForEach(LayoutStyle.allCases) { style in
                            Text(style.label).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)

                    slider(label: L10n.string("settings.carousel.cardSize"),
                           value: $store.cardSize,
                           range: 80...180,
                           suffix: "pt")
                    slider(label: L10n.string("settings.carousel.spacing"),
                           value: $store.angularStep,
                           range: 6...28,
                           suffix: "°")
                    Toggle(L10n.string("settings.carousel.showAppNames"), isOn: $store.showAppNamesInCarousel)

                    HStack {
                        Spacer()
                        Button(L10n.string("settings.carousel.restoreDefaults")) {
                            store.resetCarouselDefaults()
                        }
                    }
                }

                Section(L10n.string("settings.hiddenApps.section")) {
                    NavigationLink {
                        HiddenAppsSettingsView(store: store)
                    } label: {
                        Text(L10n.string("settings.hiddenApps.manage"))
                    }
                }

                Section(L10n.string("settings.general.section")) {
                    Toggle(L10n.string("settings.general.launchAtLogin"), isOn: $store.launchAtLogin)
                    Text(L10n.string("settings.general.launchAtLogin.description"))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Section(L10n.string("settings.about.section")) {
                    HStack {
                        Text(L10n.string("settings.about.version"))
                        Spacer()
                        Text(UpdateChecker.currentVersion())
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    Toggle(L10n.string("settings.about.autoCheckUpdates"), isOn: $store.autoCheckUpdates)

                    HStack {
                        updateStatusView
                        Spacer()
                        if let update = store.availableUpdate {
                            Button(L10n.format("settings.about.downloadFormat", update.tagName)) {
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
                                    Text(L10n.string("settings.about.checkNow"))
                                }
                            }
                            .disabled(store.isCheckingForUpdates)
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 460, height: 720)
    }

    @ViewBuilder
    private var updateStatusView: some View {
        if let err = store.updateCheckError {
            Text(err)
                .font(.system(size: 11))
                .foregroundStyle(.red)
        } else if store.availableUpdate != nil {
            Text(L10n.string("settings.about.updateAvailable"))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        } else if let last = store.lastUpdateCheck {
            Text(L10n.format(
                "settings.about.upToDateFormat",
                last.formatted(.relative(presentation: .named))
            ))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        } else {
            Text(L10n.string("settings.about.updateDescription"))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private func slider(label: String,
                        value: Binding<Double>,
                        range: ClosedRange<Double>,
                        suffix: String) -> some View {
        HStack {
            Text(label)
                .frame(width: 96, alignment: .leading)
            Slider(value: value, in: range)
            Text("\(Int(value.wrappedValue))\(suffix)")
                .monospacedDigit()
                .frame(width: 56, alignment: .trailing)
                .foregroundStyle(.secondary)
        }
    }
}
