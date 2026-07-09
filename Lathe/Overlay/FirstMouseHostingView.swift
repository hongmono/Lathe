import SwiftUI

/// 논액티베이팅 오버레이 패널에서는 SwiftUI 제스처/hover가 안 먹는다(mouseDown/moved는 도달하지만 미발화).
/// 그래서 클릭·hover를 AppKit에서 직접 잡아 **뷰 로컬(top-left) 좌표**로 콜백한다.
/// 히트테스트(어느 카드/타일인가)는 좌표를 아는 컨트롤러가 수행한다.
final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    /// 클릭 지점(뷰 로컬, top-left).
    var onClick: ((NSPoint) -> Void)?
    /// hover 이동 지점(top-left), 벗어나면 nil.
    var onHover: ((NSPoint?) -> Void)?

    private var hoverTracking: NSTrackingArea?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        onClick?(topLeftPoint(event))
        // super 미호출: 이 패널에선 SwiftUI 제스처가 안 먹고, 클릭은 여기서 최종 처리한다.
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hoverTracking { removeTrackingArea(hoverTracking) }
        // .activeAlways: 앱이 비활성/비-key여도 이벤트 수신. .inVisibleRect: rect 자동 추적.
        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
            owner: self, userInfo: nil
        )
        addTrackingArea(area)
        hoverTracking = area
    }

    // 마우스가 들어온 패널을 key로 → NSCursor.set()이 이 모니터에서도 stick(멀티모니터 커서 대응).
    override func mouseEntered(with event: NSEvent) { window?.makeKey() }
    override func mouseMoved(with event: NSEvent) { onHover?(topLeftPoint(event)) }
    override func mouseExited(with event: NSEvent) { onHover?(nil) }

    private func topLeftPoint(_ event: NSEvent) -> NSPoint {
        let local = convert(event.locationInWindow, from: nil)
        return isFlipped ? local : NSPoint(x: local.x, y: bounds.height - local.y)
    }
}
