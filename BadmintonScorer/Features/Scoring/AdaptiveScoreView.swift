import SwiftUI

// MARK: - AdaptiveScoreView
/// 設備自適應入口：依相機/iPad 手動切換 iPhoneScoreView / iPadScoreView。
/// 由 MatchSetupView 的 onSessionCreated callback 建立 session 後展示。
struct AdaptiveScoreView: View {
    @EnvironmentObject private var matchStore: MatchStore
    @Environment(\.horizontalSizeClass) private var hSize

    var body: some View {
        if hSize == .regular {
            // iPad (regular width)
            iPadScoreView()
        } else {
            // iPhone (compact width)
            iPhoneScoreView()
        }
    }
}
