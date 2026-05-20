import Foundation
import SwiftUI

// MARK: - AppComposer  (Epic H2)
/// 單一組裝進入點。在 App 啟動時建立並接線所有物件圖。
///
/// 職責：
/// 1. 建立 CameraSession / BurnInRenderer / RecorderPipeline
/// 2. 將 pipeline 注入 MatchStore
/// 3. 將 OverlayViewModel.onSnapshotUpdated 接線到 pipeline.currentSnapshot
/// 4. 提供環境物件供 SwiftUI 注入
@MainActor
final class AppComposer: ObservableObject {

    // MARK: Shared singletons
    let matchStore:      MatchStore
    let playerStore:     PlayerStore
    let overlayViewModel: OverlayViewModel
    let pipeline:        RecorderPipeline

    // MARK: Init
    init() {
        let store    = MatchStore()
        let players  = PlayerStore()
        let camera   = CameraSession()
        let burnIn   = BurnInRenderer()
        let pipe     = RecorderPipeline(cameraSession: camera, burnIn: burnIn)

        // 注入 pipeline → store
        store.pipeline = pipe

        // 建立 OverlayViewModel，接線 snapshot 更新
        let overlay = OverlayViewModel(store: store)
        overlay.onSnapshotUpdated = { [weak pipe] snapshot in
            pipe?.currentSnapshot = snapshot
        }

        self.matchStore       = store
        self.playerStore      = players
        self.overlayViewModel = overlay
        self.pipeline         = pipe
    }
}
