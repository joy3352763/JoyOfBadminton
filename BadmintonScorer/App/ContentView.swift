import SwiftUI

// MARK: - ContentView
/// App 根路由入口。
/// 依 AppRouter.route 展示對應畫面，避免小元件面對 MatchStore.state.phase 直接跟蹤。
struct ContentView: View {
    @EnvironmentObject private var matchStore: MatchStore
    @EnvironmentObject private var playerStore: PlayerStore
    @State private var router = AppRouter()

    var body: some View {
        Group {
            switch router.route {
            case .setup:
                MainTabView(onMatchStarted: {
                    router.goToMatch()
                })

            case .inMatch:
                AdaptiveScoreView(onMatchFinished: {
                    matchStore.reset()
                    router.goToSetup()
                })

            case .finished:
                // 此分支預留將來整局結果頁使用
                // 目前由 MatchFinishedView 直接呼叫 onMatchFinished
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: router.route)
    }
}

// MARK: - MainTabView
struct MainTabView: View {
    @EnvironmentObject private var playerStore: PlayerStore
    @EnvironmentObject private var matchStore: MatchStore
    let onMatchStarted: () -> Void

    @State private var selectedTab = 0
    @State private var showNotEnoughPlayersAlert = false

    private var hasEnoughPlayers: Bool {
        playerStore.players.count >= 4
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 0: 球員管理
            PlayerManagementView()
                .tabItem {
                    Label("球員", systemImage: "person.2.fill")
                }
                .tag(0)

            // Tab 1: 建立比賽
            Group {
                if hasEnoughPlayers {
                    MatchSetupView { session in
                        matchStore.startMatch(session: session)
                        onMatchStarted()
                    }
                } else {
                    NotEnoughPlayersView {
                        selectedTab = 0
                    }
                }
            }
            .tabItem {
                Label("建立比賽", systemImage: "flag.checkered")
            }
            .tag(1)
        }
    }
}

// MARK: - NotEnoughPlayersView
/// Tab 1 防呄：球員人數不足 4 人時顯示。
private struct NotEnoughPlayersView: View {
    let onAddPlayers: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text("至少需要 4 位球員")
                .font(.title2.bold())

            Text("請先到「球員」頁新增至少 4 位球員，\n再建立比賽。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: onAddPlayers) {
                Label("前往新增球員", systemImage: "plus")
                    .font(.body.bold())
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }
}
