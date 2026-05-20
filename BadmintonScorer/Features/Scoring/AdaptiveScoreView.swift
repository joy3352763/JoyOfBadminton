import SwiftUI

// MARK: - AdaptiveScoreView
/// 設備自適應入口：依 horizontalSizeClass 自動切換 iPhoneScoreView / iPadScoreView。
/// 由 ContentView 展示，接受 onMatchFinished callback 向上傳遞比賽結束事件。
struct AdaptiveScoreView: View {
    @EnvironmentObject private var matchStore: MatchStore
    @Environment(\.horizontalSizeClass) private var hSize

    let onMatchFinished: () -> Void

    var body: some View {
        if hSize == .regular {
            iPadScoreView(onMatchFinished: onMatchFinished)
        } else {
            iPhoneScoreView(onMatchFinished: onMatchFinished)
        }
    }
}
