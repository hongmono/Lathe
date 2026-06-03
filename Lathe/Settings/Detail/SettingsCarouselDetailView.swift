import SwiftUI

struct SettingsCarouselDetailView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: SettingsViewLayout.detailGroupSpacing) {
            Label(L10n.string("settings.carousel.section", language: store.appLanguage),
                  systemImage: "rectangle.stack")
                .font(.headline)
                .foregroundStyle(.primary)

            HStack(spacing: SettingsViewLayout.detailRowSpacing) {
                Text(L10n.string("settings.carousel.layout", language: store.appLanguage))

                Picker("", selection: $store.layoutStyle) {
                    ForEach(LayoutStyle.allCases) { style in
                        Text(style.label(language: store.appLanguage)).tag(style)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            HStack(spacing: SettingsViewLayout.detailRowSpacing) {
                Text(L10n.string("settings.carousel.cardSize", language: store.appLanguage))

                slider(value: $store.cardSize, range: 80...180, suffix: "pt")
            }

            HStack(spacing: SettingsViewLayout.detailRowSpacing) {
                Text(L10n.string("settings.carousel.spacing", language: store.appLanguage))

                slider(value: $store.angularStep, range: 6...28, suffix: "°")
            }

            Toggle(L10n.string("settings.carousel.showAppNames", language: store.appLanguage),
                   isOn: $store.showAppNamesInCarousel)

            Button(L10n.string("settings.carousel.restoreDefaults", language: store.appLanguage)) {
                store.resetCarouselDefaults()
            }
        }
    }

    private func slider(value: Binding<Double>,
                        range: ClosedRange<Double>,
                        suffix: String) -> some View {
        HStack(spacing: SettingsViewLayout.detailRowSpacing) {
            Slider(value: value, in: range)
            Text("\(Int(value.wrappedValue))\(suffix)")
                .monospacedDigit()
                .frame(width: SettingsCarouselDetailLayout.sliderValueWidth, alignment: .trailing)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: SettingsCarouselDetailLayout.sliderMaxWidth, alignment: .leading)
    }
}

private enum SettingsCarouselDetailLayout {
    static let sliderMaxWidth: CGFloat = 360
    static let sliderValueWidth: CGFloat = 56
}

#if DEBUG
#Preview("Carousel Detail") {
    SettingsDetailPreviewSurface {
        SettingsCarouselDetailView(
            store: SettingsPreviewStore.makeStore(suiteName: "Lathe.SettingsCarouselDetailPreview") { store in
                store.layoutStyle = .stack
                store.cardSize = 132
                store.angularStep = 18
                store.showAppNamesInCarousel = true
            }
        )
    }
}
#endif
