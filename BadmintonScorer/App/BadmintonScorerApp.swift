import SwiftUI

@main
struct BadmintonScorerApp: App {
    @StateObject private var playerStore = PlayerStore()
    @StateObject private var matchStore  = MatchStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(playerStore)
                .environmentObject(matchStore)
        }
    }
}
