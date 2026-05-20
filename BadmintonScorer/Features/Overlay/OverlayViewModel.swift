import Foundation
import Observation

// MARK: - OverlayViewModel  (Epic F1)
/// 監聽 MatchStore 的 DerivedMatchState，
/// 每個 UI cycle 產生一份 OverlaySnapshot 供 PreviewOverlay 與 BurnInRenderer 使用。
@Observable
final class OverlayViewModel {

    // MARK: Published
    private(set) var snapshot: OverlaySnapshot?

    // MARK: Dependencies
    private let matchStore: MatchStore

    // MARK: Init
    init(matchStore: MatchStore) {
        self.matchStore = matchStore
        updateSnapshot()
    }

    // MARK: Public
    /// 由 View 在 `.onChange(of: matchStore.state)` 或 task 中呼叫，
    /// 也可直接由 MatchStore 在每次 awardPoint / undo 後通知。
    func refresh() {
        updateSnapshot()
    }

    // MARK: Private
    private func updateSnapshot() {
        guard let session = matchStore.session else {
            snapshot = nil
            return
        }
        snapshot = OverlaySnapshot.from(matchStore.state, session: session)
    }
}
