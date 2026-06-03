import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    @State private var selectedPane: SettingsPane? = .general

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedPane) {
                ForEach(SettingsPane.sidebarPanes) { pane in
                    Label(L10n.string(pane.titleKey), systemImage: pane.systemImage)
                        .tag(pane)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 150, ideal: 170, max: 210)
        } detail: {
            settingsDetail(for: selectedPane ?? .general)
        }
        .frame(width: 680, height: 560)
    }

    @ViewBuilder
    private func settingsDetail(for pane: SettingsPane) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.string(pane.titleKey))
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .padding(.bottom, 2)

                switch pane {
                case .main, .general:
                    generalSettings
                case .carousel:
                    carouselSettings
                case .hiddenApps:
                    HiddenAppsSettingsView(store: store)
                case .about:
                    aboutSettings
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.regularMaterial)
    }

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsGlassSection(title: L10n.string("settings.appearance.section"),
                                 systemImage: "paintbrush") {
                VStack(spacing: 14) {
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
            }

            SettingsGlassSection(title: L10n.string("settings.general.section"),
                                 systemImage: "power") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(L10n.string("settings.general.launchAtLogin"), isOn: $store.launchAtLogin)
                    Text(L10n.string("settings.general.launchAtLogin.description"))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var carouselSettings: some View {
        SettingsGlassSection(title: L10n.string("settings.carousel.section"),
                             systemImage: "rectangle.stack") {
            VStack(spacing: 14) {
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
        }
    }

    private var aboutSettings: some View {
        SettingsGlassSection(title: L10n.string("settings.about.section"),
                             systemImage: "info.circle") {
            VStack(spacing: 14) {
                HStack {
                    Text(L10n.string("settings.about.version"))
                    Spacer()
                    Text(UpdateChecker.currentVersion())
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Divider()

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

private struct SettingsGlassSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.primary)

            content
        }
        .padding(16)
        .frame(maxWidth: 460, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary, lineWidth: 0.5)
        }
    }
}
