import XCTest
@testable import BadmintonScorer

// MARK: - Helpers
func makePlayers() throws -> (Player, Player, Player, Player) {
    let p1 = try Player(displayName: "Alice", shortName: "A1")
    let p2 = try Player(displayName: "Bob",   shortName: "B1")
    let p3 = try Player(displayName: "Carol", shortName: "C1")
    let p4 = try Player(displayName: "Dave",  shortName: "D1")
    return (p1, p2, p3, p4)
}

func makeSession() throws -> MatchSession {
    let (p1, p2, p3, p4) = try makePlayers()
    let teamA = try Team(name: "Team A", shortName: "TA", colorHex: "#FF0000", player1: p1, player2: p2)
    let teamB = try Team(name: "Team B", shortName: "TB", colorHex: "#0000FF", player1: p3, player2: p4)
    return try MatchSession(
        teamA: teamA, teamB: teamB,
        initialServerTeam: "A",
        initialServerPlayerId: p1.id,
        initialReceiverPlayerId: p3.id
    )
}

func inGameState(servingTeam: TeamSide = "A",
                 scoreA: Int = 0, scoreB: Int = 0,
                 gamesWonA: Int = 0, gamesWonB: Int = 0,
                 gameIndex: Int = 1) -> DerivedMatchState {
    var s = DerivedMatchState()
    s.phase = .inGame
    s.servingTeam = servingTeam
    s.scoreA = scoreA; s.scoreB = scoreB
    s.gamesWonA = gamesWonA; s.gamesWonB = gamesWonB
    s.currentGameIndex = gameIndex
    return s
}

// MARK: - Player
class PlayerTests: XCTestCase {
    func test_createPlayer_success() throws {
        let p = try Player(displayName: "Alice", shortName: "A1")
        XCTAssertEqual(p.shortName, "A1")
    }
    func test_emptyShortName_throws() {
        XCTAssertThrowsError(try Player(displayName: "Alice", shortName: "   "))
    }
}

// MARK: - Team
class TeamTests: XCTestCase {
    func test_duplicatePlayer_throws() throws {
        let p = try Player(displayName: "Alice", shortName: "A1")
        XCTAssertThrowsError(try Team(name: "T", shortName: "T", colorHex: "#FFF", player1: p, player2: p))
    }
    func test_validTeam_created() throws {
        let p1 = try Player(displayName: "A", shortName: "A")
        let p2 = try Player(displayName: "B", shortName: "B")
        let team = try Team(name: "Team", shortName: "T", colorHex: "#FFF", player1: p1, player2: p2)
        XCTAssertEqual(team.players.0.id, p1.id)
    }
}

// MARK: - Service Court
class ServiceCourtTests: XCTestCase {
    func test_evenScore_rightCourt() {
        XCTAssertEqual(MatchEngine.computeServiceCourt(servingTeamScore: 0),  "right")
        XCTAssertEqual(MatchEngine.computeServiceCourt(servingTeamScore: 2),  "right")
        XCTAssertEqual(MatchEngine.computeServiceCourt(servingTeamScore: 20), "right")
    }
    func test_oddScore_leftCourt() {
        XCTAssertEqual(MatchEngine.computeServiceCourt(servingTeamScore: 1),  "left")
        XCTAssertEqual(MatchEngine.computeServiceCourt(servingTeamScore: 19), "left")
    }
}

// MARK: - Award Point
class AwardPointTests: XCTestCase {
    var session: MatchSession!
    override func setUp() { super.setUp(); session = try! makeSession() }

    func test_serverTeamScores_keepsServe() throws {
        let s = MatchEngine.awardPoint(state: inGameState(servingTeam: "A"), to: "A", session: session)
        XCTAssertEqual(s.scoreA, 1)
        XCTAssertEqual(s.servingTeam, "A")
        XCTAssertEqual(s.serviceCourt, "left")
    }
    func test_receiverTeamScores_gainsServe() throws {
        let s = MatchEngine.awardPoint(state: inGameState(servingTeam: "A"), to: "B", session: session)
        XCTAssertEqual(s.scoreB, 1)
        XCTAssertEqual(s.servingTeam, "B")
        XCTAssertEqual(s.serviceCourt, "left")
    }
    func test_consecutiveScoreCourt() throws {
        var s = inGameState(servingTeam: "A", scoreA: 4)
        s = MatchEngine.awardPoint(state: s, to: "A", session: session)
        XCTAssertEqual(s.serviceCourt, "left")
        s = MatchEngine.awardPoint(state: s, to: "A", session: session)
        XCTAssertEqual(s.serviceCourt, "right")
    }
    func test_awardPoint_guard_nonInGame_isNoop() throws {
        var s = inGameState(); s.phase = .gameBreak; s.gamesWonA = 1
        let after = MatchEngine.awardPoint(state: s, to: "A", session: session)
        XCTAssertEqual(after.gamesWonA, 1)
        XCTAssertEqual(after.phase, .gameBreak)
    }
    func test_gamePoint_20_19() throws {
        let (gpa, gpb) = MatchEngine.computeGamePoint(state: inGameState(scoreA: 20, scoreB: 19), session: session)
        XCTAssertTrue(gpa); XCTAssertFalse(gpb)
    }
    func test_gamePoint_20_20_none() throws {
        let (gpa, gpb) = MatchEngine.computeGamePoint(state: inGameState(scoreA: 20, scoreB: 20), session: session)
        XCTAssertFalse(gpa); XCTAssertFalse(gpb)
    }
    func test_gamePoint_29_29_none() throws {
        let (gpa, gpb) = MatchEngine.computeGamePoint(state: inGameState(scoreA: 29, scoreB: 29), session: session)
        XCTAssertFalse(gpa); XCTAssertFalse(gpb)
    }
    func test_capPoint_30_closesGame() throws {
        let s = MatchEngine.awardPoint(state: inGameState(scoreA: 29, scoreB: 29), to: "A", session: session)
        XCTAssertEqual(s.scoreA, 30)
        XCTAssertEqual(s.gamesWonA, 1)
        XCTAssertTrue(s.phase == .gameBreak || s.phase == .finished)
    }
    func test_deuceCloseGame_22_20() throws {
        var s = inGameState(scoreA: 20, scoreB: 20)
        s = MatchEngine.awardPoint(state: s, to: "A", session: session)
        XCTAssertEqual(s.phase, .inGame)
        s = MatchEngine.awardPoint(state: s, to: "A", session: session)
        XCTAssertEqual(s.gamesWonA, 1)
        XCTAssertEqual(s.phase, .gameBreak)
    }
}

// MARK: - Best-of-3
class BestOf3Tests: XCTestCase {
    func test_winTwoGames_finishesMatch() throws {
        let session = try makeSession()
        var s = inGameState()
        for _ in 0..<21 { s = MatchEngine.awardPoint(state: s, to: "A", session: session) }
        XCTAssertEqual(s.gamesWonA, 1); XCTAssertEqual(s.phase, .gameBreak)
        s.scoreA = 0; s.scoreB = 0; s.phase = .inGame; s.currentGameIndex = 2
        for _ in 0..<21 { s = MatchEngine.awardPoint(state: s, to: "A", session: session) }
        XCTAssertEqual(s.gamesWonA, 2); XCTAssertEqual(s.phase, .finished)
        XCTAssertEqual(s.winner, "A")
    }
    func test_firstGameWin_notYetFinished() throws {
        let session = try makeSession()
        var s = inGameState()
        for _ in 0..<21 { s = MatchEngine.awardPoint(state: s, to: "B", session: session) }
        XCTAssertEqual(s.gamesWonB, 1); XCTAssertEqual(s.phase, .gameBreak)
    }
    func test_game3_decider() throws {
        let session = try makeSession()
        var s = inGameState(gamesWonA: 1, gamesWonB: 1, gameIndex: 3)
        for _ in 0..<21 { s = MatchEngine.awardPoint(state: s, to: "A", session: session) }
        XCTAssertEqual(s.phase, .finished); XCTAssertEqual(s.winner, "A")
    }
}

// MARK: - Undo
class UndoTests: XCTestCase {
    func test_undoLastPointAwarded() {
        let e = MatchEvent.pointAwarded(id: UUID(), team: "A", timestamp: Date())
        XCTAssertEqual(MatchEngine.undoLastEffectiveEvent(eventLog: [e])!.count, 0)
    }
    func test_undoNextGameStarted() {
        let e1 = MatchEvent.pointAwarded(id: UUID(), team: "A", timestamp: Date())
        let e2 = MatchEvent.nextGameStarted(id: UUID(), newGameIndex: 2, servingTeam: "B", timestamp: Date())
        let log = MatchEngine.undoLastEffectiveEvent(eventLog: [e1, e2])!
        XCTAssertEqual(log.count, 1)
        if case .pointAwarded = log[0] { } else { XCTFail("應保留 pointAwarded") }
    }
    func test_undoEmptyLog_returnsNil() {
        XCTAssertNil(MatchEngine.undoLastEffectiveEvent(eventLog: []))
    }
    func test_undoRollsBackScore() throws {
        let session = try makeSession()
        let log = (0..<3).map { _ in MatchEvent.pointAwarded(id: UUID(), team: "A", timestamp: Date()) }
        guard let newLog = MatchEngine.undoLastEffectiveEvent(eventLog: log) else { return XCTFail() }
        let after = MatchEngine.rebuildState(session: session, eventLog: newLog)
        XCTAssertEqual(after.scoreA, 2)
    }
}

// MARK: - Rebuild
class RebuildStateTests: XCTestCase {
    func test_rebuildMatchesSequential() throws {
        let session = try makeSession()
        var seq = DerivedMatchState(); seq.servingTeam = "A"; seq.phase = .inGame
        var log: [MatchEvent] = []
        for team in ["A","B","A","A","B","A","B","B","A","A"] {
            let e = MatchEvent.pointAwarded(id: UUID(), team: team, timestamp: Date())
            log.append(e)
            seq = MatchEngine.awardPoint(state: seq, to: team, session: session)
        }
        let rebuilt = MatchEngine.rebuildState(session: session, eventLog: log)
        XCTAssertEqual(rebuilt.scoreA, seq.scoreA)
        XCTAssertEqual(rebuilt.scoreB, seq.scoreB)
        XCTAssertEqual(rebuilt.servingTeam, seq.servingTeam)
    }
    func test_emptyLog_returnsInitialState() throws {
        let session = try makeSession()
        let s = MatchEngine.rebuildState(session: session, eventLog: [])
        XCTAssertEqual(s.phase, .idle); XCTAssertEqual(s.scoreA, 0)
    }
}

// MARK: - Match Point
class MatchPointTests: XCTestCase {
    func test_matchPoint_whenGamePointAndOneLegUp() throws {
        let session = try makeSession()
        let (mpa, mpb) = MatchEngine.computeMatchPoint(
            state: inGameState(scoreA: 20, scoreB: 19, gamesWonA: 1), session: session)
        XCTAssertTrue(mpa); XCTAssertFalse(mpb)
    }
    func test_noMatchPoint_whenFirstGame() throws {
        let session = try makeSession()
        let (mpa, _) = MatchEngine.computeMatchPoint(
            state: inGameState(scoreA: 20, scoreB: 19, gamesWonA: 0), session: session)
        XCTAssertFalse(mpa)
    }
}
