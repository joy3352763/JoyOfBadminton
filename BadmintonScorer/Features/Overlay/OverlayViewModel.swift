import Foundation
import Combine

// MARK: - OverlayViewModel  (Epic F1 + H2 接線)
/// 訂閱 MatchStore.state，將 DerivedMatchState 轉換為 OverlaySnapshot。
/// `onSnapshotUpdated` 由 AppComposer 注入，讓 RecorderPipeline 接收每幀快照。
@MainActor
final class OverlayViewModel: ObservableObject {

    @Published private(set) var snapshot: OverlaySnapshot?

    // AppComposer 注入：每次 snapshot 更新時呼叫
    var onSnapshotUpdated: ((OverlaySnapshot) -> Void)?

    private let store: MatchStore
    private var cancellables = Set<AnyCancellable>()

    init(store: MatchStore) {
        self.store = store
        store.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
    }

    private func handleStateChange(_ state: DerivedMatchState) {
        guard let session = store.session else { return }
        let newSnapshot = OverlaySnapshot.from(state, session: session)
        snapshot = newSnapshot
        onSnapshotUpdated?(newSnapshot)
    }
}
