import SwiftUI

/// App 根路由：依比賽狀態導向對應頁面
struct ContentView: View {
    @EnvironmentObject var matchStore: MatchStore

    var body: some View {
        Group {
            switch matchStore.state.phase {
            case .idle, .ready:
                MainTabView()
            case .inGame, .gameBreak:
                Text("ScoringView — Epic E（待實作）")
            case .finished:
                Text("MatchResultView — Epic H（待實作）")
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            Text("PlayerManagementView — Epic D1（待實作）")
                .tabItem { Label("球員", systemImage: "person.2") }
            Text("MatchSetupView — Epic D2（待實作）")
                .tabItem { Label("建立比賽", systemImage: "flag.checkered") }
        }
    }
}
