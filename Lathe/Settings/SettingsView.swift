import SwiftUI

final class SettingsNavigationState: ObservableObject {
    @Published var selectedPane: SettingsPane?

    init(selectedPane: SettingsPane? = .general) {
        self.selectedPane = selectedPane
    }
}

enum SettingsViewLayout {
    static let windowMinWidth: CGFloat = 680
    static let windowMinHeight: CGFloat = 560
    static let sidebarMinWidth: CGFloat = 180
    static let sidebarWidth: CGFloat = 200
    static let sidebarMaxWidth: CGFloat = 320
    static let detailHorizontalPadding: CGFloat = 24
    static let detailTopMargin: CGFloat = 24
    static let detailMaxWidth: CGFloat = 620
    static let detailMinWidth: CGFloat = 360
    static let sectionSpacing: CGFloat = 16
    static let detailGroupSpacing: CGFloat = 8
    static let detailRowSpacing: CGFloat = 12
    static let detailBottomPadding: CGFloat = 24
    static let detailSectionBreakHeight: CGFloat = 24
}
