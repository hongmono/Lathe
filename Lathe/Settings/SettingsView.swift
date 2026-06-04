import SwiftUI
import AppKit

final class SettingsNavigationState: ObservableObject {
    @Published var selectedPane: SettingsPane?

    init(selectedPane: SettingsPane? = .general) {
        self.selectedPane = selectedPane
    }
}

struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    @ObservedObject var navigation: SettingsNavigationState

    init(store: SettingsStore,
         navigation: SettingsNavigationState = SettingsNavigationState()) {
        self.store = store
        self.navigation = navigation
    }

    var body: some View {
        HStack(alignment: .top, spacing: SettingsViewLayout.contentSpacing) {
            SettingsSidebarView(store: store, selectedPane: $navigation.selectedPane)
                .frame(width: SettingsViewLayout.sidebarWidth)
                .frame(maxHeight: .infinity, alignment: .topLeading)

            SettingsDetailView(store: store, pane: navigation.selectedPane ?? .general)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .settingsGlassSurface(cornerRadius: SettingsViewLayout.sidebarCardCornerRadius)
        }
        .padding(SettingsViewLayout.sidebarOuterPadding)
        .ignoresSafeArea(.container, edges: .top)
        .frame(
            minWidth: SettingsViewLayout.windowMinWidth,
            minHeight: SettingsViewLayout.windowMinHeight,
            alignment: .topLeading
        )
        .background(.regularMaterial)
    }
}

struct SettingsGlassSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat
    let interactive: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            if interactive {
                content
                    .background(.regularMaterial, in: shape)
                    .glassEffect(.regular.interactive(), in: shape)
                    .overlay {
                        shape.stroke(.quaternary, lineWidth: 0.5)
                            .allowsHitTesting(false)
                    }
            } else {
                content
                    .background(.regularMaterial, in: shape)
                    .glassEffect(.regular, in: shape)
                    .overlay {
                        shape.stroke(.quaternary, lineWidth: 0.5)
                            .allowsHitTesting(false)
                    }
                }
        } else {
            fallbackSurface(content: content, shape: shape)
        }
        #else
        fallbackSurface(content: content, shape: shape)
        #endif
    }

    private func fallbackSurface(content: Content,
                                 shape: RoundedRectangle) -> some View {
        content
            .background(.regularMaterial, in: shape)
            .overlay {
                shape.stroke(.quaternary, lineWidth: 0.5)
                    .allowsHitTesting(false)
            }
    }
}

extension View {
    func settingsGlassSurface(cornerRadius: CGFloat = SettingsViewLayout.sectionCornerRadius,
                              interactive: Bool = false) -> some View {
        modifier(SettingsGlassSurfaceModifier(cornerRadius: cornerRadius, interactive: interactive))
    }
}

enum SettingsViewLayout {
    static let windowMinWidth: CGFloat = 680
    static let windowMinHeight: CGFloat = 560
    static let contentSpacing: CGFloat = 12
    static let sidebarOuterPadding: CGFloat = 12
    static let sidebarWidth: CGFloat = 178
    static let sidebarCardCornerRadius: CGFloat = 22
    static let sidebarContentTopPadding: CGFloat = 24
    static let detailHorizontalPadding: CGFloat = 24
    static let detailTopMargin: CGFloat = 24
    static let detailMaxWidth: CGFloat = 620
    static let sectionSpacing: CGFloat = 16
    static let detailGroupSpacing: CGFloat = 8
    static let detailRowSpacing: CGFloat = 12
    static let detailTitleBottomPadding: CGFloat = 2
    static let detailBottomPadding: CGFloat = 24
    static let detailSectionBreakHeight: CGFloat = 24
    static let sectionCornerRadius: CGFloat = 18
}

#if DEBUG
#Preview("Settings") {
    SettingsView(store: SettingsPreviewStore.makeStore())
        .frame(
            width: SettingsWindowChromeConfiguration.sidebarIntegrated.initialSize.width,
            height: SettingsWindowChromeConfiguration.sidebarIntegrated.initialSize.height
        )
}
#endif
