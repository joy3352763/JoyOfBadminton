import SwiftUI

// MARK: - PlayerManagementView (Epic D1)
struct PlayerManagementView: View {
    @EnvironmentObject private var playerStore: PlayerStore
    @State private var showAddSheet = false
    @State private var editingPlayer: Player? = nil

    var body: some View {
        NavigationStack {
            Group {
                if playerStore.players.isEmpty {
                    EmptyPlayersView(onAdd: { showAddSheet = true })
                } else {
                    List {
                        ForEach(playerStore.players) { player in
                            PlayerRow(player: player)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        playerStore.delete(player)
                                    } label: {
                                        Label("刪除", systemImage: "trash")
                                    }
                                    Button {
                                        editingPlayer = player
                                    } label: {
                                        Label("編輯", systemImage: "pencil")
                                    }
                                    .tint(.indigo)
                                }
                        }
                        .onDelete { playerStore.delete(at: $0) }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("球員管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showAddSheet) {
                PlayerFormView(mode: .add)
            }
            .sheet(item: $editingPlayer) { player in
                PlayerFormView(mode: .edit(player))
            }
        }
    }
}

// MARK: - PlayerRow
private struct PlayerRow: View {
    let player: Player

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Text(player.shortName)
                    .font(.system(.footnote, design: .rounded).bold())
                    .foregroundStyle(Color.accentColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(player.displayName)
                    .font(.body)
                Text(player.shortName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - EmptyPlayersView
private struct EmptyPlayersView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.sequence")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            Text("尚無球員")
                .font(.title3.bold())
            Text("點擊下方按鈕新增球員，\n最少需要 4 位才能開始比賽。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: onAdd) {
                Label("新增球員", systemImage: "person.badge.plus")
                    .font(.body.bold())
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }
}

// MARK: - PlayerFormView
enum PlayerFormMode {
    case add
    case edit(Player)
}

struct PlayerFormView: View {
    @EnvironmentObject private var playerStore: PlayerStore
    @Environment(\.dismiss) private var dismiss

    let mode: PlayerFormMode

    @State private var displayName = ""
    @State private var shortName = ""
    @State private var errorMessage: String? = nil

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("全名（例：王小明）", text: $displayName)
                        .autocorrectionDisabled()
                } header: {
                    Text("全名")
                }

                Section {
                    TextField("縮寫（例：WM，最多 4 字）", text: $shortName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                        .onChange(of: shortName) { _, new in
                            if new.count > 4 { shortName = String(new.prefix(4)) }
                        }
                } header: {
                    Text("縮寫")
                } footer: {
                    Text("將顯示於計分板與影片疊加層，建議使用 2–4 個英文大寫字母。")
                }

                if let msg = errorMessage {
                    Section {
                        Label(msg, systemImage: "exclamationmark.circle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isEditing ? "編輯球員" : "新增球員")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") { save() }
                        .disabled(shortName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { prefill() }
        }
    }

    private func prefill() {
        if case .edit(let player) = mode {
            displayName = player.displayName
            shortName   = player.shortName
        }
    }

    private func save() {
        errorMessage = nil
        do {
            switch mode {
            case .add:
                try playerStore.add(displayName: displayName, shortName: shortName)
            case .edit(let player):
                try playerStore.update(player, displayName: displayName, shortName: shortName)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
