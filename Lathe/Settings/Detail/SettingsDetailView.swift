import SwiftUI

struct SettingsDetailView: View {
    @ObservedObject var store: SettingsStore
    let pane: SettingsPane

    var body: some View {
        ScrollView {
            detailStack
                .frame(maxWidth: SettingsViewLayout.detailMaxWidth, alignment: .topLeading)
                .padding(.leading, SettingsViewLayout.detailHorizontalPadding)
                .padding(.trailing, SettingsViewLayout.detailHorizontalPadding)
                .padding(.top, SettingsViewLayout.detailTopMargin)
                .padding(.bottom, SettingsViewLayout.detailBottomPadding)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .contentMargins(.top, 0, for: .scrollContent)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var detailStack: some View {
        VStack(alignment: .leading, spacing: SettingsViewLayout.sectionSpacing) {
            Text(L10n.string(pane.titleKey, language: store.appLanguage))
                .font(.largeTitle)
                .fontWeight(.semibold)
                .padding(.bottom, SettingsViewLayout.detailTitleBottomPadding)

            switch pane {
            case .main, .general:
                SettingsGeneralDetailView(store: store)
            case .permissions:
                SettingsPermissionsDetailView(store: store)
            case .carousel:
                SettingsCarouselDetailView(store: store)
            case .hiddenApps:
                HiddenAppsSettingsView(store: store)
            case .about:
                SettingsAboutDetailView(store: store)
            }
        }
    }
}

#if DEBUG
#Preview("Detail - General") {
    SettingsDetailPreviewSurface(paddedContent: false) {
        SettingsDetailView(
            store: SettingsPreviewStore.makeStore(suiteName: "Lathe.SettingsDetail.GeneralPreview"),
            pane: .general
        )
    }
}

#Preview("Detail - Carousel") {
    SettingsDetailPreviewSurface(paddedContent: false) {
        SettingsDetailView(
            store: SettingsPreviewStore.makeStore(suiteName: "Lathe.SettingsDetail.CarouselPreview") { store in
                store.layoutStyle = .stack
                store.cardSize = 132
                store.angularStep = 18
            },
            pane: .carousel
        )
    }
}

#Preview("Detail - Permissions") {
    SettingsDetailPreviewSurface(paddedContent: false) {
        SettingsDetailView(
            store: SettingsPreviewStore.makeStore(suiteName: "Lathe.SettingsDetail.PermissionsPreview"),
            pane: .permissions
        )
    }
}

#Preview("Detail - Hidden Apps") {
    SettingsDetailPreviewSurface(paddedContent: false) {
        SettingsDetailView(
            store: SettingsPreviewStore.makeStore(suiteName: "Lathe.SettingsDetail.HiddenAppsPreview"),
            pane: .hiddenApps
        )
    }
}

#Preview("Detail - About") {
    SettingsDetailPreviewSurface(paddedContent: false) {
        SettingsDetailView(
            store: SettingsPreviewStore.makeStore(suiteName: "Lathe.SettingsDetail.AboutPreview") { store in
                store.lastUpdateCheck = Date()
            },
            pane: .about
        )
    }
}
#endif
