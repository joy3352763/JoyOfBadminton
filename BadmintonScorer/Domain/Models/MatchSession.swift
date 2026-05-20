import Foundation

// MARK: - Type Alias
typealias TeamSide = String   // "A" | "B"

// MARK: - MatchSession
struct MatchSession: Identifiable, Codable {
    let id: UUID
    let sport: String
    let bestOfGames: Int
    let pointsPerGame: Int
    let winByTwo: Bool
    let capPoint: Int
    let teamA: Team
    let teamB: Team
    let initialServerTeam: TeamSide
    let initialServerPlayerId: UUID
    let initialReceiverPlayerId: UUID
    let createdAt: Date

    init(id: UUID = UUID(), teamA: Team, teamB: Team,
         initialServerTeam: TeamSide,
         initialServerPlayerId: UUID,
         initialReceiverPlayerId: UUID) throws {
        guard initialServerTeam == "A" || initialServerTeam == "B" else {
            throw MatchSessionError.invalidServerTeam
        }
        let serverTeam   = initialServerTeam == "A" ? teamA : teamB
        let receiverTeam = initialServerTeam == "A" ? teamB : teamA
        guard serverTeam.players.0.id == initialServerPlayerId ||
              serverTeam.players.1.id == initialServerPlayerId else {
            throw MatchSessionError.serverNotInTeam
        }
        guard receiverTeam.players.0.id == initialReceiverPlayerId ||
              receiverTeam.players.1.id == initialReceiverPlayerId else {
            throw MatchSessionError.receiverNotInOppositeTeam
        }
        self.id = id; self.sport = "badminton-doubles"
        self.bestOfGames = 3; self.pointsPerGame = 21
        self.winByTwo = true; self.capPoint = 30
        self.teamA = teamA; self.teamB = teamB
        self.initialServerTeam = initialServerTeam
        self.initialServerPlayerId = initialServerPlayerId
        self.initialReceiverPlayerId = initialReceiverPlayerId
        self.createdAt = Date()
    }
}

enum MatchSessionError: LocalizedError {
    case invalidServerTeam, serverNotInTeam, receiverNotInOppositeTeam
    var errorDescription: String? {
        switch self {
        case .invalidServerTeam:          return "發球方必須為 A 或 B"
        case .serverNotInTeam:            return "發球員不屬於指定發球方隊伍"
        case .receiverNotInOppositeTeam:  return "接發員不屬於對方隊伍"
        }
    }
}
