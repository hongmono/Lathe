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

extension MissionControlController: OverlayPresenting {
    // MC는 앱 내 창 순환 개념이 없다. ⌘+` 순환은 전체 창 이동과 동일 취급.
    func cycleWindow() { next() }
    func cycleWindowPrevious() { previous() }
}
