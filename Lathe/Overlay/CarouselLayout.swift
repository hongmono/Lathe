import Foundation

enum CarouselLayout {
    struct Item: Equatable {
        let index: Int
        let relativeIndex: Int
        let angleDegrees: Double
        let offsetX: Double
        let offsetY: Double
        let scale: Double
        let opacity: Double
        let zIndex: Double
    }

    static func items(appCount: Int,
                      selectedIndex: Int,
                      style: LayoutStyle,
                      angularStep: Double,
                      maxVisibleEachSide: Int = 5) -> [Item] {
        guard appCount > 0 else { return [] }

        return (0..<appCount).compactMap { index -> Item? in
            let relativeIndex = index - selectedIndex
            let distance = abs(relativeIndex)
            guard distance <= maxVisibleEachSide else { return nil }

            return item(
                index: index,
                relativeIndex: relativeIndex,
                distance: distance,
                style: style,
                angularStep: angularStep,
                maxVisibleEachSide: maxVisibleEachSide
            )
        }
    }

    private static func item(index: Int,
                             relativeIndex: Int,
                             distance: Int,
                             style: LayoutStyle,
                             angularStep: Double,
                             maxVisibleEachSide: Int) -> Item {
        let focused = relativeIndex == 0
        let direction = relativeIndex.signum()

        switch style {
        case .fan:
            return Item(
                index: index,
                relativeIndex: relativeIndex,
                angleDegrees: Double(relativeIndex) * angularStep,
                offsetX: 0,
                offsetY: 0,
                scale: focused ? 1.04 : 1.0,
                opacity: max(1.0 - Double(distance) * 0.13, 0.35),
                zIndex: Double(maxVisibleEachSide - distance)
            )
        case .strip:
            return Item(
                index: index,
                relativeIndex: relativeIndex,
                angleDegrees: 0,
                offsetX: Double(relativeIndex) * angularStep * 10,
                offsetY: focused ? -6 : 10,
                scale: focused ? 1.06 : max(1.0 - Double(distance) * 0.06, 0.78),
                opacity: max(1.0 - Double(distance) * 0.10, 0.45),
                zIndex: Double(maxVisibleEachSide - distance)
            )
        case .stack:
            return Item(
                index: index,
                relativeIndex: relativeIndex,
                angleDegrees: Double(direction) * min(Double(distance) * 2.5, 7.5),
                offsetX: Double(relativeIndex) * angularStep * (8.0 / 3.0),
                offsetY: Double(distance) * 8,
                scale: focused ? 1.06 : max(1.0 - Double(distance) * 0.08, 0.70),
                opacity: max(1.0 - Double(distance) * 0.16, 0.32),
                zIndex: Double(maxVisibleEachSide - distance)
            )
        }
    }
}
