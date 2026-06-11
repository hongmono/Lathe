import SwiftUI

struct SettingsCarouselDetailView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: SettingsViewLayout.detailGroupSpacing) {
            Label(L10n.string("settings.carousel.section", language: store.appLanguage),
                  systemImage: "rectangle.stack")
                .font(.headline)
                .foregroundStyle(.primary)

            SettingsCarouselExampleView(
                layoutStyle: store.layoutStyle,
                cardSize: store.cardSize,
                angularStep: store.angularStep,
                fanRadius: store.fanRadius,
                fanSpacing: store.fanSpacing,
                showsAppNames: store.showAppNamesInCarousel
            )
            .padding(.vertical, SettingsCarouselDetailLayout.previewVerticalPadding)

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

            if store.layoutStyle != .fan {
                HStack(spacing: SettingsViewLayout.detailRowSpacing) {
                    Text(L10n.string("settings.carousel.spacing", language: store.appLanguage))

                    slider(value: $store.angularStep, range: 6...28, suffix: "°")
                }
            }

            if store.layoutStyle == .fan {
                HStack(spacing: SettingsViewLayout.detailRowSpacing) {
                    Text(L10n.string("settings.carousel.fanRadius", language: store.appLanguage))

                    slider(value: $store.fanRadius, range: CarouselGeometry.fanRadiusRange, suffix: "pt")
                }

                HStack(spacing: SettingsViewLayout.detailRowSpacing) {
                    Text(L10n.string("settings.carousel.fanSpacing", language: store.appLanguage))

                    slider(value: $store.fanSpacing, range: CarouselGeometry.fanSpacingRange, suffix: "pt")
                }
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
    static let previewHeight: CGFloat = 196
    static let previewVerticalPadding: CGFloat = 4
    static let previewCornerRadius: CGFloat = 16
    static let sliderMaxWidth: CGFloat = 360
    static let sliderValueWidth: CGFloat = 56
}

private struct SettingsCarouselExampleView: View {
    let layoutStyle: LayoutStyle
    let cardSize: Double
    let angularStep: Double
    let fanRadius: Double
    let fanSpacing: Double
    let showsAppNames: Bool

    private let apps = SettingsCarouselExampleApp.samples
    private let selectedIndex = 2

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: SettingsCarouselDetailLayout.previewCornerRadius, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: SettingsCarouselDetailLayout.previewCornerRadius, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 0.8)
                }

            ZStack {
                ForEach(carouselItems, id: \.index) { item in
                    SettingsCarouselExampleCard(
                        app: apps[item.index],
                        isFocused: item.relativeIndex == 0,
                        showsName: showsAppNames
                    )
                    .frame(width: previewCardWidth, height: previewCardHeight)
                    .scaleEffect(item.scale)
                    .rotationEffect(.degrees(item.angleDegrees), anchor: .center)
                    .offset(x: item.offsetX * layoutScale, y: item.offsetY * layoutScale + contentOffsetY)
                    .opacity(item.opacity)
                    .zIndex(item.zIndex)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, SettingsCarouselExampleLayout.horizontalPadding)
        }
        .frame(maxWidth: .infinity)
        .frame(height: SettingsCarouselDetailLayout.previewHeight)
        .clipShape(RoundedRectangle(cornerRadius: SettingsCarouselDetailLayout.previewCornerRadius, style: .continuous))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: layoutStyle)
        .animation(.easeInOut(duration: 0.14), value: cardSize)
        .animation(.easeInOut(duration: 0.14), value: angularStep)
        .animation(.easeInOut(duration: 0.14), value: fanRadius)
        .animation(.easeInOut(duration: 0.14), value: fanSpacing)
        .animation(.easeInOut(duration: 0.14), value: showsAppNames)
    }

    private var carouselItems: [CarouselLayout.Item] {
        CarouselLayout.items(
            appCount: apps.count,
            selectedIndex: selectedIndex,
            style: layoutStyle,
            angularStep: angularStep,
            fanRadius: fanRadius,
            fanSpacing: fanSpacing,
            maxVisibleEachSide: 2,
            currentSpaceIndices: currentSpaceIndices
        )
    }

    private var currentSpaceIndices: Set<Int> {
        Set(apps.indices.filter { apps[$0].isCurrentSpace })
    }

    private var previewCardWidth: CGFloat {
        min(max(CGFloat(cardSize) * SettingsCarouselExampleLayout.cardScale, SettingsCarouselExampleLayout.minCardWidth),
            SettingsCarouselExampleLayout.maxCardWidth)
    }

    private var previewCardHeight: CGFloat {
        previewCardWidth * SettingsCarouselExampleLayout.cardHeightRatio
    }

    private var layoutScale: CGFloat {
        previewCardWidth / max(CGFloat(cardSize), 1)
    }

    private var contentOffsetY: CGFloat {
        switch layoutStyle {
        case .fan:
            SettingsCarouselExampleLayout.fanContentOffsetY
        case .strip:
            SettingsCarouselExampleLayout.stripContentOffsetY
        case .stack:
            SettingsCarouselExampleLayout.stackContentOffsetY
        case .space:
            SettingsCarouselExampleLayout.spaceContentOffsetY
        }
    }
}

private struct SettingsCarouselExampleCard: View {
    let app: SettingsCarouselExampleApp
    let isFocused: Bool
    let showsName: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: SettingsCarouselExampleLayout.cardCornerRadius, style: .continuous)
                .fill(isFocused ? .thickMaterial : .regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: SettingsCarouselExampleLayout.cardCornerRadius, style: .continuous)
                        .stroke(.white.opacity(isFocused ? 0.34 : 0.18), lineWidth: 0.8)
                }
                .shadow(color: .black.opacity(isFocused ? 0.22 : 0.12),
                        radius: isFocused ? 16 : 8,
                        x: 0,
                        y: isFocused ? 9 : 4)

            VStack(spacing: showsName ? SettingsCarouselExampleLayout.cardContentSpacing : 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: SettingsCarouselExampleLayout.iconCornerRadius, style: .continuous)
                        .fill(app.tint.opacity(isFocused ? 0.24 : 0.16))

                    Image(systemName: app.systemImage)
                        .font(.system(size: isFocused ? 30 : 26, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(app.tint)
                }
                .frame(width: isFocused ? SettingsCarouselExampleLayout.focusedIconSide : SettingsCarouselExampleLayout.iconSide,
                       height: isFocused ? SettingsCarouselExampleLayout.focusedIconSide : SettingsCarouselExampleLayout.iconSide)

                if showsName {
                    Text(app.name)
                        .font(.system(size: isFocused ? 12 : 11, weight: isFocused ? .semibold : .medium))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(isFocused ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, SettingsCarouselExampleLayout.cardTextHorizontalPadding)
                }
            }
        }
    }
}

private struct SettingsCarouselExampleApp: Identifiable {
    let id: Int
    let name: String
    let systemImage: String
    let tint: Color
    let isCurrentSpace: Bool

    static let samples = [
        SettingsCarouselExampleApp(id: 0, name: "Finder", systemImage: "folder.fill", tint: .blue, isCurrentSpace: false),
        SettingsCarouselExampleApp(id: 1, name: "Mail", systemImage: "envelope.fill", tint: .indigo, isCurrentSpace: true),
        SettingsCarouselExampleApp(id: 2, name: "Safari", systemImage: "safari.fill", tint: .cyan, isCurrentSpace: true),
        SettingsCarouselExampleApp(id: 3, name: "Calendar", systemImage: "calendar", tint: .red, isCurrentSpace: false),
        SettingsCarouselExampleApp(id: 4, name: "Notes", systemImage: "note.text", tint: .yellow, isCurrentSpace: false)
    ]
}

private enum SettingsCarouselExampleLayout {
    static let horizontalPadding: CGFloat = 16
    static let cardScale: CGFloat = 0.72
    static let minCardWidth: CGFloat = 78
    static let maxCardWidth: CGFloat = 116
    static let cardHeightRatio: CGFloat = 1.36
    static let cardCornerRadius: CGFloat = 16
    static let iconCornerRadius: CGFloat = 12
    static let iconSide: CGFloat = 46
    static let focusedIconSide: CGFloat = 52
    static let cardContentSpacing: CGFloat = 8
    static let cardTextHorizontalPadding: CGFloat = 10
    static let fanContentOffsetY: CGFloat = 14
    static let stripContentOffsetY: CGFloat = 4
    static let stackContentOffsetY: CGFloat = 8
    static let spaceContentOffsetY: CGFloat = -2
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
