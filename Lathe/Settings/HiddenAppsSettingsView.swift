import SwiftUI
import AppKit

struct HiddenAppsSettingsView: View {
    @ObservedObject var store: SettingsStore
    @State private var hiddenAppRows: [HiddenAppRowModel] = []
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

                if hiddenAppRows.isEmpty {
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
        Table(hiddenAppRows, selection: $selectedHiddenAppBundleIdentifiers) {
            TableColumn(L10n.string("settings.hiddenApps.app")) { row in
                HStack(spacing: 8) {
                    if let icon = row.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                    Text(row.name)
                        .lineLimit(1)
                }
            }
            .width(min: 160, ideal: 220)

            TableColumn(L10n.string("settings.hiddenApps.bundleIdentifier")) { row in
                HStack(spacing: 12) {
                    Text(row.bundleIdentifier)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer(minLength: 12)

                    Toggle(L10n.string("settings.hiddenApps.hidden"),
                           isOn: excludedBinding(for: row.bundleIdentifier))
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .help(L10n.string("settings.hiddenApps.hidden"))
                        .accessibilityLabel(L10n.string("settings.hiddenApps.hidden"))
                }
            }
            .width(min: 280, ideal: 420)
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
        let options = AppExclusionOption.options(
            from: apps,
            excludedBundleIdentifiers: listedBundleIdentifiers,
            installedApps: installedApps
        )
        hiddenAppRows = HiddenAppRowModel.rows(
            from: options,
            excludedBundleIdentifiers: store.excludedBundleIdentifiers
        )
        let currentBundleIdentifiers = Set(hiddenAppRows.map(\.bundleIdentifier))
        selectedHiddenAppBundleIdentifiers.formIntersection(currentBundleIdentifiers)
    }
}
