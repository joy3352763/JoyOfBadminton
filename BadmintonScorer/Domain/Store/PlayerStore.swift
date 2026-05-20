import Foundation
import Combine

// MARK: - PlayerStore
/// Task A1：球員資料本地持久化（UserDefaults，可替換為 SwiftData）
@MainActor
final class PlayerStore: ObservableObject {
    @Published private(set) var players: [Player] = []

    private let storageKey = "badminton.players"

    init() { load() }

    // MARK: CRUD
    func add(displayName: String, shortName: String) throws {
        let player = try Player(displayName: displayName, shortName: shortName)
        players.append(player)
        save()
    }

    func update(_ player: Player, displayName: String, shortName: String) throws {
        guard !shortName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw PlayerError.emptyShortName
        }
        guard let idx = players.firstIndex(where: { $0.id == player.id }) else { return }
        players[idx].displayName = displayName
        players[idx].shortName   = shortName
        save()
    }

    func delete(_ player: Player) {
        players.removeAll { $0.id == player.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        players.remove(atOffsets: offsets)
        save()
    }

    // MARK: Persistence
    private func save() {
        guard let data = try? JSONEncoder().encode(players) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([Player].self, from: data)
        else { return }
        players = saved
    }
}
