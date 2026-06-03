import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    @State private var selectedPane: SettingsPane? = .general
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        HStack(spacing: 0) {
            if SettingsSidebarVisibilityToggle.isVisible(columnVisibility) {
                settingsSidebar
                    .frame(width: SettingsViewLayout.sidebarWidth)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            settingsDetail(
                for: selectedPane ?? .general,
                sidebarVisible: SettingsSidebarVisibilityToggle.isVisible(columnVisibility)
            )
        }
        .ignoresSafeArea(.container, edges: .top)
        .frame(
            minWidth: SettingsViewLayout.windowMinWidth,
            minHeight: SettingsViewLayout.windowMinHeight,
            alignment: .topLeading
        )
        .background {
            SettingsSidebarShortcutMonitor(columnVisibility: $columnVisibility)
                .frame(width: 0, height: 0)
        }
        .background(.regularMaterial)
        .animation(.easeInOut(duration: 0.16), value: SettingsSidebarVisibilityToggle.isVisible(columnVisibility))
    }

    private var settingsSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer(minLength: 0)
                sidebarToggleButton
            }
            .padding(.top, SettingsViewLayout.sidebarChromeTopPadding)
            .padding(.trailing, SettingsViewLayout.sidebarHorizontalPadding + 2)
            .frame(height: SettingsViewLayout.sidebarTopMargin, alignment: .topTrailing)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(SettingsPane.sidebarPanes) { pane in
                    settingsSidebarButton(for: pane)
                }
            }
            .padding(.horizontal, SettingsViewLayout.sidebarHorizontalPadding)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial)
        .overlay(alignment: .trailing) {
            Divider().opacity(0.45)
        }
    }

    private var sidebarToggleButton: some View {
        Button {
            columnVisibility = SettingsSidebarVisibilityToggle.toggled(columnVisibility)
        } label: {
            Image(systemName: "sidebar.left")
                .font(.system(size: 18, weight: .medium))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .accessibilityLabel(L10n.string("settings.sidebar.toggle"))
    }

    private func settingsSidebarButton(for pane: SettingsPane) -> some View {
        let isSelected = selectedPane == pane

        return Button {
            selectedPane = pane
        } label: {
            HStack(spacing: 12) {
                Image(systemName: pane.systemImage)
                    .font(.system(size: 16))
                    .frame(width: 18)

                Text(L10n.string(pane.titleKey))
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.accentColor)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func settingsDetail(for pane: SettingsPane, sidebarVisible: Bool) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    if !sidebarVisible {
                        sidebarToggleButton
                    }

                    Text(L10n.string(pane.titleKey))
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                }
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
            .padding(
                .leading,
                sidebarVisible
                    ? SettingsViewLayout.detailHorizontalPadding
                    : SettingsViewLayout.collapsedDetailLeadingPadding
            )
            .padding(.trailing, SettingsViewLayout.detailHorizontalPadding)
            .padding(
                .top,
                sidebarVisible
                    ? SettingsViewLayout.detailTopMargin
                    : SettingsViewLayout.collapsedDetailTopMargin
            )
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .offset(y: SettingsViewLayout.detailContentOffsetY)
        }
        .contentMargins(.top, 0, for: .scrollContent)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.regularMaterial)
    }

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsGlassSection(title: L10n.string("settings.appearance.section"),
                                 systemImage: "paintbrush") {
                VStack(alignment: .leading, spacing: 14) {
                    formRow(label: L10n.string("settings.appearance.language")) {
                        Picker("", selection: $store.appLanguage) {
                            ForEach(AppLanguage.allCases) { language in
                                Text(language.label).tag(language)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }

                    formRow(label: L10n.string("settings.appearance.theme")) {
                        Picker("", selection: $store.appearance) {
                            ForEach(Appearance.allCases) { a in
                                Text(a.label).tag(a)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }
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
            VStack(alignment: .leading, spacing: 14) {
                formRow(label: L10n.string("settings.carousel.layout")) {
                    Picker("", selection: $store.layoutStyle) {
                        ForEach(LayoutStyle.allCases) { style in
                            Text(style.label).tag(style)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                slider(label: L10n.string("settings.carousel.cardSize"),
                       value: $store.cardSize,
                       range: 80...180,
                       suffix: "pt")
                slider(label: L10n.string("settings.carousel.spacing"),
                       value: $store.angularStep,
                       range: 6...28,
                       suffix: "°")
                Toggle(L10n.string("settings.carousel.showAppNames"), isOn: $store.showAppNamesInCarousel)

                Button(L10n.string("settings.carousel.restoreDefaults")) {
                    store.resetCarouselDefaults()
                }
            }
        }
    }

    private var aboutSettings: some View {
        SettingsGlassSection(title: L10n.string("settings.about.section"),
                             systemImage: "info.circle") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Text(L10n.string("settings.about.version"))
                    Text(UpdateChecker.currentVersion())
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Divider()

                Toggle(L10n.string("settings.about.autoCheckUpdates"), isOn: $store.autoCheckUpdates)

                HStack(alignment: .center, spacing: 12) {
                    updateStatusView
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

    private func formRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .frame(width: SettingsViewLayout.formLabelWidth, alignment: .leading)

            content()
                .frame(width: SettingsViewLayout.segmentedControlWidth, alignment: .leading)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        HStack(spacing: 12) {
            Text(label)
                .frame(width: SettingsViewLayout.formLabelWidth, alignment: .leading)
            Slider(value: value, in: range)
            Text("\(Int(value.wrappedValue))\(suffix)")
                .monospacedDigit()
                .frame(width: 56, alignment: .trailing)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: SettingsViewLayout.formControlMaxWidth, alignment: .leading)
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
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary, lineWidth: 0.5)
        }
    }
}

enum SettingsSidebarVisibilityToggle {
    static func toggled(_ visibility: NavigationSplitViewVisibility) -> NavigationSplitViewVisibility {
        switch visibility {
        case .detailOnly:
            return .all
        default:
            return .detailOnly
        }
    }

    static func isVisible(_ visibility: NavigationSplitViewVisibility) -> Bool {
        switch visibility {
        case .detailOnly:
            return false
        default:
            return true
        }
    }
}

private struct SettingsSidebarShortcutMonitor: NSViewRepresentable {
    @Binding var columnVisibility: NavigationSplitViewVisibility

    func makeCoordinator() -> Coordinator {
        Coordinator(columnVisibility: $columnVisibility)
    }

    func makeNSView(context: Context) -> NSView {
        context.coordinator.attach()
        return NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.columnVisibility = $columnVisibility
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.detach()
    }

    final class Coordinator {
        var columnVisibility: Binding<NavigationSplitViewVisibility>
        private var monitor: Any?

        init(columnVisibility: Binding<NavigationSplitViewVisibility>) {
            self.columnVisibility = columnVisibility
        }

        func attach() {
            guard monitor == nil else { return }

            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self,
                      Self.isSidebarShortcut(event) else {
                    return event
                }

                self.columnVisibility.wrappedValue = SettingsSidebarVisibilityToggle.toggled(
                    self.columnVisibility.wrappedValue
                )
                return nil
            }
        }

        func detach() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
            monitor = nil
        }

        private static func isSidebarShortcut(_ event: NSEvent) -> Bool {
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard flags.contains(.command),
                  !flags.contains(.shift),
                  !flags.contains(.option),
                  !flags.contains(.control),
                  event.charactersIgnoringModifiers?.lowercased() == "b" else {
                return false
            }
            return true
        }
    }
}

enum SettingsViewLayout {
    static let windowMinWidth: CGFloat = 680
    static let windowMinHeight: CGFloat = 560
    static let sidebarWidth: CGFloat = 178
    static let sidebarTopMargin: CGFloat = 52
    static let sidebarChromeTopPadding: CGFloat = 20
    static let sidebarHorizontalPadding: CGFloat = 12
    static let detailHorizontalPadding: CGFloat = 24
    static let detailTopMargin: CGFloat = 24
    static let collapsedDetailTopMargin: CGFloat = 60
    static let collapsedDetailLeadingPadding: CGFloat = 96
    static let detailContentOffsetY: CGFloat = 0
    static let formLabelWidth: CGFloat = 112
    static let segmentedControlWidth: CGFloat = 260
    static let formControlMaxWidth: CGFloat = 460
}
