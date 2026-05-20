import SwiftUI
import Observation

// MARK: - AppRoute
enum AppRoute: Equatable {
    case setup     // 賽前：球員管理 + 比賽設定
    case inMatch   // 計分中
}

// MARK: - AppRouter
/// App 層級導航狀態機。
/// @Observable 需要 iOS 17+ / Xcode 15+。
@MainActor
@Observable
final class AppRouter {
    var route: AppRoute = .setup

    func goToMatch() { route = .inMatch }
    func goToSetup() { route = .setup }
}
