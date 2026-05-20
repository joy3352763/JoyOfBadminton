import SwiftUI

@main
struct BadmintonScorerApp: App {

    // AppComposer 建立並持有完整的物件圖
    @StateObject private var composer = AppComposer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Domain / Store
                .environmentObject(composer.matchStore)
                .environmentObject(composer.playerStore)
                // Overlay
                .environmentObject(composer.overlayViewModel)
                // Pipeline（供 UI 觀察 recordingState）
                .environmentObject(composer.pipeline)
        }
    }
}
