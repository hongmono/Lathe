import SwiftUI
import AppKit

struct HiddenAppsSettingsView: View {
    @ObservedObject var store: SettingsStore
    @State private var appExclusionOptions: [AppExclusionOption] = []
    @State private var selectedHiddenAppBundleIdentifiers: Set<String> = []

    var body: some View {
        Form {
            Section(L10n.string("settings.hiddenApps.section")) {
                hiddenAppsList
            }
        }
        .formStyle(.grouped)
        .navigationTitle(L10n.string("settings.hiddenApps.manage"))
        .onAppear {
            refreshAppExclusionOptions()
        }
        .onReceive(store.$excludedBundleIdentifiers) { _ in
            refreshAppExclusionOptions()
        }
        .onReceive(store.$hiddenAppBundleIdentifiers) { _ in
            refreshAppExclusionOptions()
        }
    }

    private var hiddenAppsList: some View {
        VStack(spacing: 0) {
            ZStack {
                hiddenAppsTable

                if appExclusionOptions.isEmpty {
                    Text(L10n.string("settings.hiddenApps.empty"))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack(spacing: 0) {
                Button {
                    addHiddenApp()
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.borderless)
                .help(L10n.string("settings.hiddenApps.add"))
                .accessibilityLabel(L10n.string("settings.hiddenApps.add"))

                Divider()
                    .frame(height: 16)

                Button {
                    removeSelectedHiddenApps()
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.borderless)
                .disabled(selectedHiddenAppBundleIdentifiers.isEmpty)
                .help(L10n.string("settings.hiddenApps.remove"))
                .accessibilityLabel(L10n.string("settings.hiddenApps.remove"))

                Spacer()
            }
            .frame(height: 26)
            .padding(.horizontal, 6)
            .background(.thinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var hiddenAppsTable: some View {
        Table(appExclusionOptions, selection: $selectedHiddenAppBundleIdentifiers) {
            TableColumn(L10n.string("settings.hiddenApps.app")) { option in
                HStack(spacing: 8) {
                    if let icon = option.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                    Text(option.name)
                        .lineLimit(1)
                }
            }
            .width(min: 140, ideal: 170)

            TableColumn(L10n.string("settings.hiddenApps.bundleIdentifier")) { option in
                Text(option.bundleIdentifier)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .width(min: 170, ideal: 210)

            TableColumn(L10n.string("settings.hiddenApps.hidden")) { option in
                Toggle("", isOn: excludedBinding(for: option.bundleIdentifier))
                    .labelsHidden()
            }
            .width(64)
        }
        .frame(height: 360)
    }

    private func excludedBinding(for bundleIdentifier: String) -> Binding<Bool> {
        Binding {
            store.isExcluded(bundleIdentifier: bundleIdentifier)
        } set: { excluded in
            store.setExcluded(excluded, bundleIdentifier: bundleIdentifier)
        }
    }

    private func addHiddenApp() {
        let panel = ApplicationOpenPanel.make(title: L10n.string("settings.hiddenApps.add"))

        guard panel.runModal() == .OK,
              let url = panel.url,
              let metadata = AppBundleMetadata.metadata(applicationURL: url) else {
            return
        }

        store.addHiddenApp(bundleIdentifier: metadata.bundleIdentifier)
        selectedHiddenAppBundleIdentifiers = [metadata.bundleIdentifier]
        refreshAppExclusionOptions()
    }

    private func removeSelectedHiddenApps() {
        guard !selectedHiddenAppBundleIdentifiers.isEmpty else { return }

        store.removeHiddenApps(bundleIdentifiers: selectedHiddenAppBundleIdentifiers)
        selectedHiddenAppBundleIdentifiers.removeAll()
        refreshAppExclusionOptions()
    }

    private func refreshAppExclusionOptions() {
        let apps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .map { app in
                AppEntry(
                    id: app.processIdentifier,
                    bundleIdentifier: app.bundleIdentifier,
                    name: app.localizedName ?? app.bundleIdentifier ?? L10n.string("app.unknown"),
                    icon: app.icon ?? NSImage()
                )
            }
        let listedBundleIdentifiers = store.hiddenAppBundleIdentifiers
        let installedApps = listedBundleIdentifiers.compactMap {
            AppBundleMetadata.resolve(bundleIdentifier: $0)
        }
        appExclusionOptions = AppExclusionOption.options(
            from: apps,
            excludedBundleIdentifiers: listedBundleIdentifiers,
            installedApps: installedApps
        )
        let currentBundleIdentifiers = Set(appExclusionOptions.map(\.bundleIdentifier))
        selectedHiddenAppBundleIdentifiers.formIntersection(currentBundleIdentifiers)
    }
}
