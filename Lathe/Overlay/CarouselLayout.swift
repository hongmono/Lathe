import Foundation

enum CarouselGeometry {
    static let defaultMaxVisibleEachSide = 5
    static let fanMaxVisibleEachSide = 3
    static let defaultFanRadius: Double = 520
    static let fanRadiusRange: ClosedRange<Double> = 320...1_200
    static let defaultFanSpacing: Double = 120
    static let fanSpacingRange: ClosedRange<Double> = 0...180

    static func maxVisibleEachSide(for style: LayoutStyle) -> Int {
        switch style {
        case .fan:
            fanMaxVisibleEachSide
        case .strip, .stack, .space:
            defaultMaxVisibleEachSide
        }
    }

    static func clampedFanRadius(_ value: Double) -> Double {
        guard value.isFinite else { return defaultFanRadius }
        return min(max(value, fanRadiusRange.lowerBound), fanRadiusRange.upperBound)
    }

    static func storedFanRadius(_ value: Double?) -> Double {
        guard let value, value.isFinite, fanRadiusRange.contains(value) else {
            return defaultFanRadius
        }
        return value
    }

    static func clampedFanSpacing(_ value: Double) -> Double {
        guard value.isFinite else { return defaultFanSpacing }
        return min(max(value, fanSpacingRange.lowerBound), fanSpacingRange.upperBound)
    }

    static func storedFanSpacing(_ value: Double?) -> Double {
        guard let value, value.isFinite else { return defaultFanSpacing }
        return clampedFanSpacing(value)
    }
}

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
                      fanRadius: Double = CarouselGeometry.defaultFanRadius,
                      fanSpacing: Double = CarouselGeometry.defaultFanSpacing,
                      maxVisibleEachSide: Int = 5,
                      currentSpaceIndices: Set<Int> = []) -> [Item] {
        guard appCount > 0 else { return [] }

        if style == .space, !currentSpaceIndices.isEmpty {
            let hasVisibleCurrentSpaceItem = (0..<appCount).contains { index in
                currentSpaceIndices.contains(index) && abs(index - selectedIndex) <= maxVisibleEachSide
            }

            if hasVisibleCurrentSpaceItem {
                return spaceItems(
                    appCount: appCount,
                    selectedIndex: selectedIndex,
                    angularStep: angularStep,
                    maxVisibleEachSide: maxVisibleEachSide,
                    currentSpaceIndices: currentSpaceIndices
                )
            }
        }

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
                fanRadius: fanRadius,
                fanSpacing: fanSpacing,
                maxVisibleEachSide: maxVisibleEachSide
            )
        }
    }

    private static func spaceItems(appCount: Int,
                                   selectedIndex: Int,
                                   angularStep: Double,
                                   maxVisibleEachSide: Int,
                                   currentSpaceIndices: Set<Int>) -> [Item] {
        let visibleIndices = (0..<appCount).filter { index in
            abs(index - selectedIndex) <= maxVisibleEachSide
        }
        let currentIndices = visibleIndices.filter { currentSpaceIndices.contains($0) }
        let otherIndices = visibleIndices.filter { !currentSpaceIndices.contains($0) }
        let currentRanks = Dictionary(uniqueKeysWithValues: currentIndices.enumerated().map { ($0.element, $0.offset) })
        let otherRanks = Dictionary(uniqueKeysWithValues: otherIndices.enumerated().map { ($0.element, $0.offset) })
        let primarySpacing = angularStep * 7.5
        let secondarySpacing = angularStep * 7.0
        let focusedZIndex = Double(maxVisibleEachSide * 3 + 20)

        return visibleIndices.map { index in
            let relativeIndex = index - selectedIndex
            let distance = abs(relativeIndex)
            let focused = relativeIndex == 0

            if let rank = currentRanks[index] {
                return Item(
                    index: index,
                    relativeIndex: relativeIndex,
                    angleDegrees: 0,
                    offsetX: centeredOffset(rank: rank, count: currentIndices.count, spacing: primarySpacing),
                    offsetY: focused ? -28 : -18,
                    scale: focused ? 1.08 : 1.02,
                    opacity: max(1.0 - Double(distance) * 0.06, 0.68),
                    zIndex: focused ? focusedZIndex : Double(maxVisibleEachSide * 2 - distance + 10)
                )
            }

            let rank = otherRanks[index] ?? 0
            let direction = relativeIndex.signum()
            return Item(
                index: index,
                relativeIndex: relativeIndex,
                angleDegrees: Double(direction) * min(Double(distance) * 1.8, 6.0),
                offsetX: centeredOffset(rank: rank, count: otherIndices.count, spacing: secondarySpacing),
                offsetY: 74 + Double(distance) * 5,
                scale: focused ? 1.04 : max(0.92 - Double(distance) * 0.035, 0.68),
                opacity: max(0.82 - Double(distance) * 0.08, 0.38),
                zIndex: focused ? focusedZIndex : Double(maxVisibleEachSide - distance)
            )
        }
    }

    private static func centeredOffset(rank: Int, count: Int, spacing: Double) -> Double {
        (Double(rank) - (Double(count) - 1) / 2) * spacing
    }

    private static func item(index: Int,
                             relativeIndex: Int,
                             distance: Int,
                             style: LayoutStyle,
                             angularStep: Double,
                             fanRadius: Double,
                             fanSpacing: Double,
                             maxVisibleEachSide: Int) -> Item {
        let focused = relativeIndex == 0
        let direction = relativeIndex.signum()

        switch style {
        case .fan, .space:
            let clampedFanRadius = CarouselGeometry.clampedFanRadius(fanRadius)
            let clampedFanSpacing = CarouselGeometry.clampedFanSpacing(fanSpacing)
            let radians = Double(relativeIndex) * clampedFanSpacing / clampedFanRadius
            return Item(
                index: index,
                relativeIndex: relativeIndex,
                angleDegrees: radians * 180 / .pi,
                offsetX: clampedFanRadius * sin(radians),
                offsetY: clampedFanRadius * (1 - cos(radians)),
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
