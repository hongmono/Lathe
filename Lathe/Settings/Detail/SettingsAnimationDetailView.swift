import SwiftUI

struct SettingsAnimationDetailView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: SettingsViewLayout.detailGroupSpacing) {
            Label(L10n.string("settings.animation.section", language: store.appLanguage),
                  systemImage: "play.circle")
                .font(.headline)
                .foregroundStyle(.primary)

            Toggle(L10n.string("settings.carousel.animateOnOpen", language: store.appLanguage),
                   isOn: $store.animateCarouselPresentation)

            Spacer().frame(height: SettingsViewLayout.detailSectionBreakHeight)

            Label(L10n.string("settings.carousel.windowListAnimation", language: store.appLanguage),
                  systemImage: "macwindow.on.rectangle")
                .font(.headline)
                .foregroundStyle(.primary)

            HStack(spacing: SettingsViewLayout.detailRowSpacing) {
                Text(L10n.string("settings.animation.style", language: store.appLanguage))

                Picker("", selection: $store.windowListAnimationStyle) {
                    ForEach(WindowListAnimationStyle.allCases) { style in
                        Text(style.label(language: store.appLanguage)).tag(style)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            SettingsWindowListAnimationPreview(
                animationStyle: store.windowListAnimationStyle,
                animationSpeed: store.windowListAnimationSpeed,
                animationDelay: store.windowListAnimationDelay,
                appLanguage: store.appLanguage
            )

            animationSlider(
                titleKey: "settings.carousel.windowListAnimation.speed",
                value: $store.windowListAnimationSpeed,
                range: SettingsStore.windowListAnimationSpeedRange,
                suffix: "×"
            )

            animationSlider(
                titleKey: "settings.animation.windowListAnimation.delay",
                value: $store.windowListAnimationDelay,
                range: SettingsStore.windowListAnimationDelayRange,
                suffix: L10n.string("settings.animation.seconds.short", language: store.appLanguage)
            )

            Button(L10n.string("settings.animation.restoreDefaults", language: store.appLanguage)) {
                store.resetAnimationDefaults()
            }
        }
    }

    private func animationSlider(
        titleKey: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        suffix: String
    ) -> some View {
        HStack(spacing: SettingsViewLayout.detailRowSpacing) {
            Text(L10n.string(titleKey, language: store.appLanguage))

            Slider(value: value, in: range, step: 0.1)

            Text(value.wrappedValue.formatted(.number.precision(.fractionLength(1))) + suffix)
                .monospacedDigit()
                .frame(width: SettingsAnimationDetailLayout.sliderValueWidth, alignment: .trailing)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: SettingsAnimationDetailLayout.sliderMaxWidth, alignment: .leading)
    }
}

private enum SettingsAnimationDetailLayout {
    static let previewHeight: CGFloat = 152
    static let previewScale: CGFloat = 0.86
    static let previewCornerRadius: CGFloat = 16
    static let sliderMaxWidth: CGFloat = 360
    static let sliderValueWidth: CGFloat = 52
}

private struct SettingsWindowListAnimationPreview: View {
    let animationStyle: WindowListAnimationStyle
    let animationSpeed: Double
    let animationDelay: Double
    let appLanguage: AppLanguage

    @State private var replayID = 0

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: SettingsAnimationDetailLayout.previewCornerRadius,
                    style: .continuous
                )
                .fill(Color.primary.opacity(0.035))
                .overlay {
                    RoundedRectangle(
                        cornerRadius: SettingsAnimationDetailLayout.previewCornerRadius,
                        style: .continuous
                    )
                    .stroke(.primary.opacity(0.08), lineWidth: 0.8)
                }

                WindowListView(
                    items: previewItems,
                    selectedIndex: 0,
                    presentationStyle: animationStyle,
                    presentationSpeed: animationSpeed,
                    presentationDelay: animationDelay
                )
                .scaleEffect(SettingsAnimationDetailLayout.previewScale)
                .id(PreviewID(
                    animationStyle: animationStyle,
                    animationSpeed: animationSpeed,
                    animationDelay: animationDelay,
                    replayID: replayID
                ))
            }
            .frame(maxWidth: .infinity)
            .frame(height: SettingsAnimationDetailLayout.previewHeight)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: SettingsAnimationDetailLayout.previewCornerRadius,
                    style: .continuous
                )
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            Button {
                replayID += 1
            } label: {
                Label(
                    L10n.string("settings.carousel.windowListAnimation.replay", language: appLanguage),
                    systemImage: "arrow.clockwise"
                )
            }
            .buttonStyle(.borderless)
        }
    }

    private var previewItems: [WindowSelectionItem] {
        [
            .window(previewWindow(id: -101, titleKey: "settings.carousel.windowListAnimation.preview.first")),
            .window(previewWindow(id: -102, titleKey: "settings.carousel.windowListAnimation.preview.second")),
            .window(previewWindow(id: -103, titleKey: "settings.carousel.windowListAnimation.preview.third")),
        ]
    }

    private func previewWindow(id: Int, titleKey: String) -> WindowEntry {
        WindowEntry(
            id: id,
            title: L10n.string(titleKey, language: appLanguage),
            pathSummary: nil,
            isMinimized: false
        )
    }

    private struct PreviewID: Hashable {
        let animationStyle: WindowListAnimationStyle
        let animationSpeed: Double
        let animationDelay: Double
        let replayID: Int
    }
}

#if DEBUG
#Preview("Animation Detail") {
    SettingsDetailPreviewSurface {
        SettingsAnimationDetailView(
            store: SettingsPreviewStore.makeStore(suiteName: "Lathe.SettingsAnimationDetailPreview")
        )
    }
}
#endif
