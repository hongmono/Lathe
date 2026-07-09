import AppKit

final class OverlayPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 940, height: 940),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .canJoinAllApplications, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        // 카드/타일 클릭 전환을 위해 마우스 이벤트를 받는다. 숨을 땐 orderOut이라 이벤트 대상이 아니다.
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true   // hover 트래킹용
        hidesOnDeactivate = false
    }

    // 카드/타일 클릭이 SwiftUI에 전달되려면 key가 될 수 있어야 한다.
    // .nonactivatingPanel이라 key가 돼도 앱은 활성화되지 않아 뒤 앱 포커스는 유지된다.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
