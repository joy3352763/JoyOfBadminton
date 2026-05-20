import Foundation

// MARK: - Player

struct Player: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var displayName: String
    var shortName: String

    init(id: UUID = UUID(), displayName: String, shortName: String) throws {
        guard !shortName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw PlayerError.emptyShortName
        }
        self.id = id
        self.displayName = displayName
        self.shortName = shortName
    }
}

enum PlayerError: LocalizedError {
    case emptyShortName
    var errorDescription: String? {
        switch self {
        case .emptyShortName: return "球員短名稱不可為空"
        }
    }
}
