import Foundation

/// ⌘+Tab 오버레이 공통 인터페이스. 캐러셀/미션 컨트롤 컨트롤러가 공유한다.
@MainActor
protocol OverlayPresenting: AnyObject {
    var isVisible: Bool { get }
    func next()
    func previous()
    func cycleWindow()
    func cycleWindowPrevious()
    func currentSelection() -> OverlaySelection?
    func recordWindowActivation()
    func hide(animated: Bool)
}

extension OverlayController: OverlayPresenting {}

// MissionControlController는 cycleWindow/cycleWindowPrevious를 직접 구현한다
// (선택된 앱 스택 안에서 창 순환).
extension MissionControlController: OverlayPresenting {}
