import SwiftUI
import AppKit

struct HiddenAppsSettingsView: View {
    @ObservedObject var store: SettingsStore
    @State private var hiddenAppRows: [HiddenAppRowModel] = []
    @State private var selectedHiddenAppBundleIdentifiers: Set<String> = []

    var body: some View {
        hiddenAppsList
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear {
                refreshAppExclusionOptions()
            }
            .onReceive(store.$excludedBundleIdentifiers) { _ in
                refreshAppExclusionOptions()
            }
            .onReceive(store.$hiddenAppBundleIdentifiers) { _ in
                refreshAppExclusionOptions()
            }
            .onReceive(store.$appLanguage) { _ in
                refreshAppExclusionOptions()
            }
    }

    private var hiddenAppsList: some View {
        VStack(spacing: 0) {
            hiddenAppsHeader

            Divider()

            ZStack(alignment: .topLeading) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(hiddenAppRows) { row in
                            HiddenAppRowView(
                                row: row,
                                isSelected: selectedHiddenAppBundleIdentifiers.contains(row.bundleIdentifier),
                                isHidden: excludedBinding(for: row.bundleIdentifier),
                                hiddenLabel: L10n.string("settings.hiddenApps.hidden", language: store.appLanguage)
                            ) {
                                toggleSelection(for: row.bundleIdentifier)
                            }

                            Divider()
                                .padding(.leading, HiddenAppsListLayout.rowHorizontalPadding)
                        }
                    }
                }

                if hiddenAppRows.isEmpty {
                    Text(L10n.string("settings.hiddenApps.empty", language: store.appLanguage))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .padding(HiddenAppsListLayout.rowHorizontalPadding)
                }
            }
            .frame(height: HiddenAppsListLayout.listHeight)

            Divider()

            hiddenAppsControlBar
        }
        .settingsGlassSurface(interactive: true)
    }

    private var hiddenAppsHeader: some View {
        HStack(spacing: HiddenAppsListLayout.columnSpacing) {
            Text(L10n.string("settings.hiddenApps.app", language: store.appLanguage))
                .frame(width: HiddenAppsListLayout.appColumnWidth, alignment: .leading)

            Text(L10n.string("settings.hiddenApps.bundleIdentifier", language: store.appLanguage))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(L10n.string("settings.hiddenApps.hidden", language: store.appLanguage))
                .frame(width: HiddenAppsListLayout.toggleColumnWidth, alignment: .trailing)
        }
        .font(.system(size: 13, weight: .semibold))
        .padding(.horizontal, HiddenAppsListLayout.rowHorizontalPadding)
        .frame(height: HiddenAppsListLayout.headerHeight)
        .background(.ultraThinMaterial)
    }

    private var hiddenAppsControlBar: some View {
        HStack(spacing: 0) {
            Button {
                addHiddenApp()
            } label: {
                Image(systemName: "plus")
                    .frame(
                        width: HiddenAppsListLayout.controlButtonSize,
                        height: HiddenAppsListLayout.controlButtonSize
                    )
            }
            .buttonStyle(.borderless)
            .help(L10n.string("settings.hiddenApps.add", language: store.appLanguage))
            .accessibilityLabel(L10n.string("settings.hiddenApps.add", language: store.appLanguage))

            Divider()
                .frame(height: HiddenAppsListLayout.controlDividerHeight)

            Button {
                removeSelectedHiddenApps()
            } label: {
                Image(systemName: "minus")
                    .frame(
                        width: HiddenAppsListLayout.controlButtonSize,
                        height: HiddenAppsListLayout.controlButtonSize
                    )
            }
            .buttonStyle(.borderless)
            .disabled(selectedHiddenAppBundleIdentifiers.isEmpty)
            .help(L10n.string("settings.hiddenApps.remove", language: store.appLanguage))
            .accessibilityLabel(L10n.string("settings.hiddenApps.remove", language: store.appLanguage))

            Spacer()
        }
        .frame(height: HiddenAppsListLayout.controlBarHeight)
        .padding(.horizontal, HiddenAppsListLayout.controlBarHorizontalPadding)
        .background(.thinMaterial)
    }

    private func toggleSelection(for bundleIdentifier: String) {
        if selectedHiddenAppBundleIdentifiers.contains(bundleIdentifier) {
            selectedHiddenAppBundleIdentifiers.remove(bundleIdentifier)
        } else {
            selectedHiddenAppBundleIdentifiers.insert(bundleIdentifier)
        }
    }

    private func excludedBinding(for bundleIdentifier: String) -> Binding<Bool> {
        Binding {
            store.isExcluded(bundleIdentifier: bundleIdentifier)
        } set: { excluded in
            store.setExcluded(excluded, bundleIdentifier: bundleIdentifier)
        }
    }

    private func addHiddenApp() {
        let panel = ApplicationOpenPanel.make(title: L10n.string("settings.hiddenApps.add", language: store.appLanguage))

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
                    name: app.localizedName ?? app.bundleIdentifier ?? L10n.string("app.unknown", language: store.appLanguage),
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

#if DEBUG
#Preview("Hidden Apps Detail") {
    SettingsDetailPreviewSurface(height: 520) {
        HiddenAppsSettingsView(
            store: SettingsPreviewStore.makeStore(suiteName: "Lathe.HiddenAppsDetailPreview")
        )
    }
}
#endif

private enum HiddenAppsListLayout {
    static let appColumnWidth: CGFloat = 150
    static let toggleColumnWidth: CGFloat = 58
    static let headerHeight: CGFloat = 32
    static let listHeight: CGFloat = 360
    static let rowHeight: CGFloat = 44
    static let rowHorizontalPadding: CGFloat = 16
    static let columnSpacing: CGFloat = 12
    static let appNameSpacing: CGFloat = 8
    static let iconSize: CGFloat = 22
    static let bundleIdentifierFontSize: CGFloat = 12
    static let controlButtonSize: CGFloat = 22
    static let controlDividerHeight: CGFloat = 16
    static let controlBarHeight: CGFloat = 26
    static let controlBarHorizontalPadding: CGFloat = 6
}

private struct HiddenAppRowView: View {
    let row: HiddenAppRowModel
    let isSelected: Bool
    @Binding var isHidden: Bool
    let hiddenLabel: String
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: HiddenAppsListLayout.columnSpacing) {
            HStack(spacing: HiddenAppsListLayout.appNameSpacing) {
                if let icon = row.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(
                            width: HiddenAppsListLayout.iconSize,
                            height: HiddenAppsListLayout.iconSize
                        )
                }

                Text(row.name)
                    .lineLimit(1)
            }
            .frame(width: HiddenAppsListLayout.appColumnWidth, alignment: .leading)

            Text(row.bundleIdentifier)
                .font(.system(size: HiddenAppsListLayout.bundleIdentifierFontSize))
                .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Toggle(hiddenLabel, isOn: $isHidden)
                .labelsHidden()
                .toggleStyle(.switch)
                .frame(width: HiddenAppsListLayout.toggleColumnWidth, alignment: .trailing)
                .help(hiddenLabel)
                .accessibilityLabel(hiddenLabel)
                .accessibilityIdentifier("hidden-app-toggle-\(row.bundleIdentifier)")
        }
        .padding(.horizontal, HiddenAppsListLayout.rowHorizontalPadding)
        .frame(height: HiddenAppsListLayout.rowHeight)
        .foregroundStyle(isSelected ? .white : .primary)
        .background(isSelected ? Color.accentColor.opacity(0.9) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}
