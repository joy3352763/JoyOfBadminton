import Foundation
import Combine

// MARK: - MatchStore
/// 管理當前比賽的 session、eventLog 與衍生狀態。
/// 是唯一可呼叫 MatchEngine 並發出 MatchEvent 的入口。
@MainActor
final class MatchStore: ObservableObject {
    @Published private(set) var session: MatchSession?
    @Published private(set) var eventLog: [MatchEvent] = []
    @Published private(set) var state: DerivedMatchState = DerivedMatchState()

    // MARK: - Setup

    func startMatch(session: MatchSession) {
        self.session  = session
        self.eventLog = []
        self.state    = MatchEngine.rebuildState(session: session, eventLog: [])
        appendEvent(.matchCreated(id: UUID(), sessionId: session.id, timestamp: Date()))
        appendEvent(.initialServerSelected(
            id: UUID(),
            servingTeam: session.initialServerTeam,
            servingPlayerId: session.initialServerPlayerId,
            receivingPlayerId: session.initialReceiverPlayerId,
            timestamp: Date()
        ))
    }

    /// 比賽結束後重置狀態，回到 setup 流程。
    func reset() {
        session  = nil
        eventLog = []
        state    = DerivedMatchState()
    }

    // MARK: - Recording

    func startRecording() {
        appendEvent(.recordingStarted(id: UUID(), timestamp: Date()))
    }

    func pauseRecording() {
        appendEvent(.recordingPaused(id: UUID(), timestamp: Date()))
    }

    func resumeRecording() {
        appendEvent(.recordingResumed(id: UUID(), timestamp: Date()))
    }

    func stopRecording() {
        appendEvent(.recordingStopped(id: UUID(), timestamp: Date()))
    }

    // MARK: - Game Actions

    func awardPoint(to team: TeamSide) {
        guard state.phase == .inGame, session != nil else { return }
        appendEvent(.pointAwarded(id: UUID(), team: team, timestamp: Date()))
    }

    func startNextGame(servingTeam: TeamSide) {
        guard state.phase == .gameBreak, session != nil else { return }
        let nextIndex = state.currentGameIndex + 1
        appendEvent(.nextGameStarted(
            id: UUID(),
            newGameIndex: nextIndex,
            servingTeam: servingTeam,
            timestamp: Date()
        ))
    }

    // MARK: - Undo

    var canUndo: Bool {
        eventLog.contains { $0.isEffective }
    }

    func undo() {
        guard let session,
              let newLog = MatchEngine.undoLastEffectiveEvent(eventLog: eventLog) else { return }
        eventLog = newLog
        eventLog.append(.undoPerformed(id: UUID(), timestamp: Date()))
        state = MatchEngine.rebuildState(session: session, eventLog: eventLog)
    }

    // MARK: - Private

    private func appendEvent(_ event: MatchEvent) {
        eventLog.append(event)
        if let session {
            state = MatchEngine.rebuildState(session: session, eventLog: eventLog)
        }
    }
}
