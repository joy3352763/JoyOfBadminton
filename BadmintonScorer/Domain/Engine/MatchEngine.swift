import Foundation

// MARK: - MatchEngine
/// 純函數式規則引擎：所有方法為 static，無副作用，方便單元測試與 AI 分工。
struct MatchEngine {

    // MARK: Service Court
    /// 雙打發球區規則：發球方分數偶數→右發，奇數→左發
    static func computeServiceCourt(servingTeamScore: Int) -> String {
        servingTeamScore % 2 == 0 ? "right" : "left"
    }

    // MARK: Game Point
    /// 局點旗標計算
    /// - 一般：某隊達 pts-1 且領先
    /// - Deuce（雙方 >= pts）：領先 1 分即局點
    /// - Cap 邊界：任一隊達 cap-1 即局點
    static func computeGamePoint(
        state: DerivedMatchState,
        session: MatchSession
    ) -> (isGPA: Bool, isGPB: Bool) {
        let pts = session.pointsPerGame
        let cap = session.capPoint
        let sA = state.scoreA, sB = state.scoreB

        var isGPA = false, isGPB = false

        if sA >= cap - 1 { isGPA = true }
        if sB >= cap - 1 { isGPB = true }

        if sA >= pts - 1 && sA > sB && sA < cap - 1 { isGPA = true }
        if sB >= pts - 1 && sB > sA && sB < cap - 1 { isGPB = true }

        if sA >= pts && sB >= pts {
            isGPA = (sA == sB + 1)
            isGPB = (sB == sA + 1)
        }

        return (isGPA, isGPB)
    }

    // MARK: Match Point
    /// 局點成立且距贏得比賽僅差 1 局時升格為賽點
    static func computeMatchPoint(
        state: DerivedMatchState,
        session: MatchSession
    ) -> (isMPA: Bool, isMPB: Bool) {
        let needed = (session.bestOfGames / 2) + 1
        let (isGPA, isGPB) = computeGamePoint(state: state, session: session)
        return (
            isGPA && state.gamesWonA == needed - 1,
            isGPB && state.gamesWonB == needed - 1
        )
    }

    // MARK: Close Game / Finish Match
    static func shouldCloseGame(state: DerivedMatchState, session: MatchSession) -> Bool {
        let pts = session.pointsPerGame
        let cap = session.capPoint
        let sA = state.scoreA, sB = state.scoreB

        if sA >= cap || sB >= cap             { return true }
        if sA >= pts && sA - sB >= 2          { return true }
        if sB >= pts && sB - sA >= 2          { return true }
        return false
    }

    static func shouldFinishMatch(state: DerivedMatchState, session: MatchSession) -> Bool {
        let needed = (session.bestOfGames / 2) + 1
        return state.gamesWonA >= needed || state.gamesWonB >= needed
    }

    // MARK: Award Point
    /// 核心計分函式。
    /// - 非 inGame 狀態時直接回傳原狀態（防止 gameBreak/finished 下重複關局）
    static func awardPoint(
        state: DerivedMatchState,
        to team: TeamSide,
        session: MatchSession
    ) -> DerivedMatchState {
        guard state.phase == .inGame else { return state }

        var s = state

        // 1. 加分
        if team == "A" { s.scoreA += 1 } else { s.scoreB += 1 }

        // 2. 發球權
        let newScore = team == "A" ? s.scoreA : s.scoreB
        if team == s.servingTeam {
            s.serviceCourt = computeServiceCourt(servingTeamScore: newScore)
        } else {
            s.servingTeam = team
            s.serviceCourt = computeServiceCourt(servingTeamScore: newScore)
            // MVP 簡化：servingPlayerId 切換留待 Epic E 整合玩家選取後補充
        }

        // 3. 局點 / 賽點旗標
        let (isGPA, isGPB) = computeGamePoint(state: s, session: session)
        s.isGamePointA = isGPA
        s.isGamePointB = isGPB
        let (isMPA, isMPB) = computeMatchPoint(state: s, session: session)
        s.isMatchPointA = isMPA
        s.isMatchPointB = isMPB

        // 4. 關局判斷
        if shouldCloseGame(state: s, session: session) {
            let gameWinner: TeamSide = s.scoreA > s.scoreB ? "A" : "B"
            if gameWinner == "A" { s.gamesWonA += 1 } else { s.gamesWonB += 1 }

            if shouldFinishMatch(state: s, session: session) {
                s.phase = .finished
                s.winner = gameWinner
            } else {
                s.phase = .gameBreak
                swap(&s.courtEndsA, &s.courtEndsB)   // 換邊
            }
        }

        return s
    }

    // MARK: Apply Event
    /// 將單一 MatchEvent 套用至狀態，回傳新狀態（純函數）。
    static func applyEvent(
        state: DerivedMatchState,
        event: MatchEvent,
        session: MatchSession
    ) -> DerivedMatchState {
        var s = state
        s.eventCursor += 1

        switch event {
        case .initialServerSelected(_, let servingTeam, let servingPlayerId, let receivingPlayerId, _):
            s.servingTeam       = servingTeam
            s.servingPlayerId   = servingPlayerId
            s.receivingPlayerId = receivingPlayerId
            s.serviceCourt      = computeServiceCourt(servingTeamScore: 0)
            s.phase             = .ready

        case .recordingStarted:
            s.phase = .inGame

        case .pointAwarded(_, let team, _):
            s = awardPoint(state: s, to: team, session: session)

        case .nextGameStarted(_, let newGameIndex, let servingTeam, _):
            s.currentGameIndex = newGameIndex
            s.scoreA           = 0
            s.scoreB           = 0
            s.servingTeam      = servingTeam
            s.serviceCourt     = computeServiceCourt(servingTeamScore: 0)
            s.isGamePointA     = false
            s.isGamePointB     = false
            s.isMatchPointA    = false
            s.isMatchPointB    = false
            s.phase            = .inGame

        case .gameClosed(_, let winner, _):
            if winner == "A" { s.gamesWonA += 1 } else { s.gamesWonB += 1 }
            s.phase = shouldFinishMatch(state: s, session: session) ? .finished : .gameBreak

        case .matchFinished(_, let winner, _):
            s.phase  = .finished
            s.winner = winner

        case .recordingPaused, .recordingResumed, .recordingStopped:
            break

        case .undoPerformed, .matchCreated, .playersAssigned:
            break
        }

        return s
    }

    // MARK: Undo
    /// 移除 eventLog 中最後一筆有效事件，回傳新 log。
    /// 無可撤銷事件時回傳 nil。
    static func undoLastEffectiveEvent(eventLog: [MatchEvent]) -> [MatchEvent]? {
        guard let idx = eventLog.indices.reversed()
            .first(where: { eventLog[$0].isEffective }) else { return nil }
        var newLog = eventLog
        newLog.remove(at: idx)
        return newLog
    }

    // MARK: Rebuild State
    /// Event Sourcing：從 session + 完整 eventLog 重建 DerivedMatchState。
    static func rebuildState(session: MatchSession, eventLog: [MatchEvent]) -> DerivedMatchState {
        var state = DerivedMatchState()
        state.servingPlayerId   = session.initialServerPlayerId
        state.receivingPlayerId = session.initialReceiverPlayerId
        state.servingTeam       = session.initialServerTeam
        for event in eventLog {
            state = applyEvent(state: state, event: event, session: session)
        }
        return state
    }
}
