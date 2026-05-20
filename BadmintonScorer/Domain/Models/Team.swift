import Foundation

// MARK: - Team

struct Team: Identifiable, Equatable {
    let id: UUID
    var name: String
    var shortName: String
    var colorHex: String
    var players: (Player, Player)

    init(id: UUID = UUID(), name: String, shortName: String, colorHex: String,
         player1: Player, player2: Player) throws {
        guard player1.id != player2.id else { throw TeamError.duplicatePlayer }
        self.id = id; self.name = name; self.shortName = shortName
        self.colorHex = colorHex; self.players = (player1, player2)
    }

    static func == (lhs: Team, rhs: Team) -> Bool { lhs.id == rhs.id }
}

extension Team: Codable {
    enum CodingKeys: String, CodingKey { case id, name, shortName, colorHex, player1, player2 }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        shortName = try c.decode(String.self, forKey: .shortName)
        colorHex = try c.decode(String.self, forKey: .colorHex)
        let p1 = try c.decode(Player.self, forKey: .player1)
        let p2 = try c.decode(Player.self, forKey: .player2)
        players = (p1, p2)
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(name, forKey: .name)
        try c.encode(shortName, forKey: .shortName); try c.encode(colorHex, forKey: .colorHex)
        try c.encode(players.0, forKey: .player1); try c.encode(players.1, forKey: .player2)
    }
}

enum TeamError: LocalizedError {
    case duplicatePlayer
    var errorDescription: String? {
        switch self { case .duplicatePlayer: return "同一球員不可在同一隊中重複出現" }
    }
}
