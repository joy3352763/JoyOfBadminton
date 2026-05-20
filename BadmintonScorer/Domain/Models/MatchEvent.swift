import Foundation

// MARK: - TeamSide
typealias TeamSide = String  // "A" | "B"

// MARK: - ServiceCourt
/// 發球區：左側或右側。定義於 Domain 層，供 Overlay / Engine 共用。
enum ServiceCourt: String, Codable, Equatable {
    case left
    case right
}

// MARK: - MatchEvent
enum MatchEvent: Codable, Equatable {
    case matchCreated(id: UUID, sessionId: UUID, timestamp: Date)
    case playersAssigned(id: UUID, teamA: Team, teamB: Team, timestamp: Date)
    case initialServerSelected(id: UUID, servingTeam: TeamSide, servingPlayerId: UUID, receivingPlayerId: UUID, timestamp: Date)
    case recordingStarted(id: UUID, timestamp: Date)
    case pointAwarded(id: UUID, team: TeamSide, timestamp: Date)
    case undoPerformed(id: UUID, timestamp: Date)
    case gameClosed(id: UUID, winner: TeamSide, timestamp: Date)
    case nextGameStarted(id: UUID, newGameIndex: Int, servingTeam: TeamSide, timestamp: Date)
    case recordingPaused(id: UUID, timestamp: Date)
    case recordingResumed(id: UUID, timestamp: Date)
    case matchFinished(id: UUID, winner: TeamSide, timestamp: Date)
    case recordingStopped(id: UUID, timestamp: Date)

    var eventId: UUID {
        switch self {
        case .matchCreated(let id, _, _),
             .playersAssigned(let id, _, _, _),
             .initialServerSelected(let id, _, _, _, _),
             .recordingStarted(let id, _),
             .pointAwarded(let id, _, _),
             .undoPerformed(let id, _),
             .gameClosed(let id, _, _),
             .nextGameStarted(let id, _, _, _),
             .recordingPaused(let id, _),
             .recordingResumed(let id, _),
             .matchFinished(let id, _, _),
             .recordingStopped(let id, _):
            return id
        }
    }

    var timestamp: Date {
        switch self {
        case .matchCreated(_, _, let t),
             .playersAssigned(_, _, _, let t),
             .initialServerSelected(_, _, _, _, let t),
             .recordingStarted(_, let t),
             .pointAwarded(_, _, let t),
             .undoPerformed(_, let t),
             .gameClosed(_, _, let t),
             .nextGameStarted(_, _, _, let t),
             .recordingPaused(_, let t),
             .recordingResumed(_, let t),
             .matchFinished(_, _, let t),
             .recordingStopped(_, let t):
            return t
        }
    }

    var isEffective: Bool {
        switch self {
        case .pointAwarded, .nextGameStarted, .gameClosed, .matchFinished,
             .initialServerSelected, .recordingStarted,
             .recordingPaused, .recordingResumed, .recordingStopped:
            return true
        case .undoPerformed, .matchCreated, .playersAssigned:
            return false
        }
    }
}

// MARK: - DerivedMatchState
struct DerivedMatchState: Equatable {

    enum Phase: String, Codable, Equatable {
        case idle
        case ready
        case inGame
        case gameBreak
        case finished
    }

    var phase: Phase = .idle
    var currentGameIndex: Int = 1
    var gamesWonA: Int = 0
    var gamesWonB: Int = 0
    var scoreA: Int = 0
    var scoreB: Int = 0
    var servingTeam: TeamSide = "A"
    var servingPlayerId: UUID = UUID()
    var receivingPlayerId: UUID = UUID()
    var serviceCourt: ServiceCourt = .right   // 升級為 enum
    var courtEndsA: String = "north"
    var courtEndsB: String = "south"
    var isGamePointA: Bool = false
    var isGamePointB: Bool = false
    var isMatchPointA: Bool = false
    var isMatchPointB: Bool = false
    var winner: TeamSide? = nil
    var eventCursor: Int = 0
}
