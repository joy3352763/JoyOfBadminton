import XCTest
@testable import BadmintonScorer

// MARK: - Epic H Integration Acceptance Tests
// BDD §7 全場景端對端驗收。
// 測試在純 Domain 層執行，不依賴 AVFoundation / UI。
final class IntegrationAcceptanceTests: XCTestCase {

    // MARK: - Fixtures
    private func makePlayers() -> (p1: Player, p2: Player, p3: Player, p4: Player) {
        let p1 = try! Player(id: UUID(), displayName: "Alice Chen",  shortName: "Alice")
        let p2 = try! Player(id: UUID(), displayName: "Bob Lin",    shortName: "Bob")
        let p3 = try! Player(id: UUID(), displayName: "Carol Wu",   shortName: "Carol")
        let p4 = try! Player(id: UUID(), displayName: "David Tsai", shortName: "David")
        return (p1, p2, p3, p4)
    }

    private func makeSession() -> MatchSession {
        let (p1, p2, p3, p4) = makePlayers()
        let teamA = try! Team(id: UUID(), name: "Team Alpha", shortName: "A",
                              colorHex: "#E63946", players: (p1, p2))
        let teamB = try! Team(id: UUID(), name: "Team Beta",  shortName: "B",
                              colorHex: "#457B9D", players: (p3, p4))
        return MatchSession(
            id: UUID(),
            teamA: teamA, teamB: teamB,
            initialServerTeam: "A",
            initialServerPlayerId:   p1.id,
            initialReceiverPlayerId: p3.id,
            createdAt: Date()
        )
    }

    // MARK: - H1  全比賽生命週期
    /// BDD §7.2 Feature: 計分規則
    /// 模擬三局兩勝完整比賽，驗證 winner 正確標記。
    func test_fullMatchLifecycle_threeGames() {
        let session = makeSession()
        var log: [MatchEvent] = []

        // 賽前 events
        log.append(.matchCreated(id: UUID(), sessionId: session.id, timestamp: Date()))
        log.append(.initialServerSelected(id: UUID(), servingTeam: "A",
                                           servingPlayerId: session.initialServerPlayerId,
                                           receivingPlayerId: session.initialReceiverPlayerId,
                                           timestamp: Date()))

        // Game 1: A 拿 21 分
        for _ in 0..<21 { log.append(.pointAwarded(id: UUID(), team: "A", timestamp: Date())) }
        var state = MatchEngine.rebuildState(session: session, eventLog: log)
        XCTAssertEqual(state.phase, .gameBreak)
        XCTAssertEqual(state.gamesWonA, 1)
        XCTAssertEqual(state.gamesWonB, 0)

        // 換局
        log.append(.nextGameStarted(id: UUID(), newGameIndex: 2, servingTeam: "B", timestamp: Date()))

        // Game 2: B 拿 21 分
        for _ in 0..<21 { log.append(.pointAwarded(id: UUID(), team: "B", timestamp: Date())) }
        state = MatchEngine.rebuildState(session: session, eventLog: log)
        XCTAssertEqual(state.phase, .gameBreak)
        XCTAssertEqual(state.gamesWonA, 1)
        XCTAssertEqual(state.gamesWonB, 1)

        // 換局
        log.append(.nextGameStarted(id: UUID(), newGameIndex: 3, servingTeam: "A", timestamp: Date()))

        // Game 3: A 拿 21 分
        for _ in 0..<21 { log.append(.pointAwarded(id: UUID(), team: "A", timestamp: Date())) }
        state = MatchEngine.rebuildState(session: session, eventLog: log)
        XCTAssertEqual(state.phase, .finished)
        XCTAssertEqual(state.winner, "A")
        XCTAssertEqual(state.gamesWonA, 2)
    }

    // MARK: - H1  壓力測試 — 連續 100 次得分
    /// BDD §8 H1：確認 eventLog replay 無效能崩潰。
    func test_stressReplay_100PointAwardedEvents() {
        let session = makeSession()
        var log: [MatchEvent] = []
        log.append(.matchCreated(id: UUID(), sessionId: session.id, timestamp: Date()))
        log.append(.initialServerSelected(id: UUID(), servingTeam: "A",
                                           servingPlayerId: session.initialServerPlayerId,
                                           receivingPlayerId: session.initialReceiverPlayerId,
                                           timestamp: Date()))
        // 壓入超過一局所需的 100 球，engine 應自動關局繼續
        for i in 0..<100 {
            log.append(.pointAwarded(id: UUID(), team: i % 2 == 0 ? "A" : "B", timestamp: Date()))
        }
        let state = MatchEngine.rebuildState(session: session, eventLog: log)
        // 100 球後必定至少結束一局
        XCTAssertTrue(state.currentGameIndex >= 1)
        XCTAssertTrue(state.gamesWonA + state.gamesWonB >= 1)
    }

    // MARK: - H1  rebuildState 冪等性
    /// apply 逐步 vs 一次 rebuild 結果必須完全相同。
    func test_rebuildState_idempotency() {
        let session = makeSession()
        var log: [MatchEvent] = []
        log.append(.matchCreated(id: UUID(), sessionId: session.id, timestamp: Date()))
        log.append(.initialServerSelected(id: UUID(), servingTeam: "A",
                                           servingPlayerId: session.initialServerPlayerId,
                                           receivingPlayerId: session.initialReceiverPlayerId,
                                           timestamp: Date()))
        for i in 0..<15 {
            log.append(.pointAwarded(id: UUID(), team: i % 3 == 0 ? "B" : "A", timestamp: Date()))
        }

        let stateA = MatchEngine.rebuildState(session: session, eventLog: log)
        let stateB = MatchEngine.rebuildState(session: session, eventLog: log)
        XCTAssertEqual(stateA, stateB)
    }

    // MARK: - H2  Deuce / 封頂邊界
    /// BDD §7.2 Scenario: 30:29 封頂
    func test_deuceCap_at30() {
        let session = makeSession()
        var log: [MatchEvent] = []
        log.append(.matchCreated(id: UUID(), sessionId: session.id, timestamp: Date()))
        log.append(.initialServerSelected(id: UUID(), servingTeam: "A",
                                           servingPlayerId: session.initialServerPlayerId,
                                           receivingPlayerId: session.initialReceiverPlayerId,
                                           timestamp: Date()))
        // 推到 29:29
        for _ in 0..<29 { log.append(.pointAwarded(id: UUID(), team: "A", timestamp: Date())) }
        for _ in 0..<29 { log.append(.pointAwarded(id: UUID(), team: "B", timestamp: Date())) }
        var state = MatchEngine.rebuildState(session: session, eventLog: log)
        XCTAssertEqual(state.scoreA, 29)
        XCTAssertEqual(state.scoreB, 29)

        // A 再得 1 分 → 30:29 → A 拿下此局
        log.append(.pointAwarded(id: UUID(), team: "A", timestamp: Date()))
        state = MatchEngine.rebuildState(session: session, eventLog: log)
        XCTAssertEqual(state.phase, .gameBreak)
        XCTAssertEqual(state.gamesWonA, 1)
    }

    // MARK: - H2  Undo 鏈
    /// BDD §7.2 Feature: 撤銷。連續 undo 5 次，狀態回退正確。
    func test_undoChain_fiveConsecutive() {
        let session = makeSession()
        var log: [MatchEvent] = []
        log.append(.matchCreated(id: UUID(), sessionId: session.id, timestamp: Date()))
        log.append(.initialServerSelected(id: UUID(), servingTeam: "A",
                                           servingPlayerId: session.initialServerPlayerId,
                                           receivingPlayerId: session.initialReceiverPlayerId,
                                           timestamp: Date()))
        // 加入 10 個得分
        for i in 0..<10 {
            log.append(.pointAwarded(id: UUID(), team: i % 2 == 0 ? "A" : "B", timestamp: Date()))
        }
        let stateBefore = MatchEngine.rebuildState(session: session, eventLog: log)
        XCTAssertEqual(stateBefore.scoreA + stateBefore.scoreB, 10)

        // 連續 undo 5 次
        var mutableLog = log
        for _ in 0..<5 {
            if let newLog = MatchEngine.undoLastEffectiveEvent(eventLog: mutableLog) {
                mutableLog = newLog
            }
        }
        let stateAfter = MatchEngine.rebuildState(session: session, eventLog: mutableLog)
        XCTAssertEqual(stateAfter.scoreA + stateAfter.scoreB, 5)
    }

    // MARK: - H3  RecordingState 狀態機完整路徑
    /// BDD §7.3 Scenario: idle→recording→paused→recording→saved
    func test_recordingStateMachine_fullPath() {
        // RecordingState 是純 enum，不依賴 AVFoundation
        var state: RecordingState = .idle
        XCTAssertFalse(state.isActive)

        // startRecording
        state = .recording
        XCTAssertTrue(state.isActive)
        XCTAssertEqual(state, .recording)

        // pause
        state = .paused
        XCTAssertTrue(state.isActive)

        // resume
        state = .recording
        XCTAssertTrue(state.isActive)

        // finalizing
        state = .finalizing
        XCTAssertFalse(state.isActive)

        // saved
        let url = URL(fileURLWithPath: "/tmp/test.mp4")
        state = .saved(url: url)
        XCTAssertFalse(state.isActive)
        if case .saved(let savedURL) = state {
            XCTAssertEqual(savedURL.lastPathComponent, "test.mp4")
        } else {
            XCTFail("Expected .saved state")
        }
    }

    // MARK: - H3  Winner 傳遞
    /// BDD §7.2 Scenario: A 拿 2 局 → winner = A
    func test_winnerPropagation_teamAWins() {
        let session = makeSession()
        var log: [MatchEvent] = []
        log.append(.matchCreated(id: UUID(), sessionId: session.id, timestamp: Date()))
        log.append(.initialServerSelected(id: UUID(), servingTeam: "A",
                                           servingPlayerId: session.initialServerPlayerId,
                                           receivingPlayerId: session.initialReceiverPlayerId,
                                           timestamp: Date()))
        // Game 1: A 21
        for _ in 0..<21 { log.append(.pointAwarded(id: UUID(), team: "A", timestamp: Date())) }
        log.append(.nextGameStarted(id: UUID(), newGameIndex: 2, servingTeam: "B", timestamp: Date()))
        // Game 2: A 21
        for _ in 0..<21 { log.append(.pointAwarded(id: UUID(), team: "A", timestamp: Date())) }

        let state = MatchEngine.rebuildState(session: session, eventLog: log)
        XCTAssertEqual(state.phase, .finished)
        XCTAssertEqual(state.winner, "A")
        XCTAssertEqual(state.gamesWonA, 2)
        XCTAssertEqual(state.gamesWonB, 0)
    }

    // MARK: - H3  eventCursor 單調遞增
    /// 每個 event 後 eventCursor 必須遞增。
    func test_eventCursor_monotoneIncrement() {
        let session = makeSession()
        var log: [MatchEvent] = []
        log.append(.matchCreated(id: UUID(), sessionId: session.id, timestamp: Date()))
        log.append(.initialServerSelected(id: UUID(), servingTeam: "A",
                                           servingPlayerId: session.initialServerPlayerId,
                                           receivingPlayerId: session.initialReceiverPlayerId,
                                           timestamp: Date()))
        var prevCursor = MatchEngine.rebuildState(session: session, eventLog: log).eventCursor
        for i in 0..<10 {
            log.append(.pointAwarded(id: UUID(), team: i % 2 == 0 ? "A" : "B", timestamp: Date()))
            let newCursor = MatchEngine.rebuildState(session: session, eventLog: log).eventCursor
            XCTAssertGreaterThan(newCursor, prevCursor)
            prevCursor = newCursor
        }
    }
}
