import SwiftUI

// MARK: - AppRoute
enum AppRoute: Equatable {
    case setup       // 賽前：球員管理 + 比賽設定
    case inMatch     // 計分中
    case finished    // 比賽結束（短暫，將回到 setup）
}

// MARK: - AppRouter
/// App 層級導航狀態機。
/// 依賴 MatchStore.state.phase 自動切換路由，
/// 也可由 UI 主動呼叫。
@MainActor
@Observable
final class AppRouter {
    var route: AppRoute = .setup

    func goToMatch() {
        route = .inMatch
    }

    func goToSetup() {
        route = .setup
    }
}
