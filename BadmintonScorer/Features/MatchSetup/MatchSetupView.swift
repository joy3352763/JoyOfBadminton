import SwiftUI

// MARK: - MatchSetupView (Epic D2)
/// 三步驟精靈：選 A 隊 → 選 B 隊 → 設定發球，建立 MatchSession。
struct MatchSetupView: View {
    @EnvironmentObject private var playerStore: PlayerStore
    @Environment(\.dismiss) private var dismiss

    /// 外部注入的 callback：setup 完成後呼叫，傳入已建立的 MatchSession。
    var onSessionCreated: (MatchSession) -> Void

    // MARK: Step 1 & 2 — 隊伍選擇
    @State private var teamAPlayer1: Player? = nil
    @State private var teamAPlayer2: Player? = nil
    @State private var teamAName: String = "Team A"
    @State private var teamAShort: String = "TA"
    @State private var teamAColor: Color = .red

    @State private var teamBPlayer1: Player? = nil
    @State private var teamBPlayer2: Player? = nil
    @State private var teamBName: String = "Team B"
    @State private var teamBShort: String = "TB"
    @State private var teamBColor: Color = .blue

    // MARK: Step 3 — 發球設定
    @State private var servingTeamSide: TeamSide = "A"
    @State private var servingPlayer: Player? = nil
    @State private var receivingPlayer: Player? = nil

    @State private var step: Int = 0   // 0 = A隊, 1 = B隊, 2 = 發球
    @State private var validationError: String? = nil

    // MARK: Derived
    private var allPlayers: [Player] { playerStore.players }

    private var teamAPlayers: [Player] {
        [teamAPlayer1, teamAPlayer2].compactMap { $0 }
    }
    private var teamBPlayers: [Player] {
        [teamBPlayer1, teamBPlayer2].compactMap { $0 }
    }

    private var servingTeamPlayers: [Player] {
        servingTeamSide == "A" ? teamAPlayers : teamBPlayers
    }
    private var receivingTeamPlayers: [Player] {
        servingTeamSide == "A" ? teamBPlayers : teamAPlayers
    }

    private var stepTitle: String {
        ["選擇 A 隊", "選擇 B 隊", "設定發球"][step]
    }

    // MARK: Body
    var body: some View {
        NavigationStack {
            Form {
                switch step {
                case 0: teamSectionView(side: "A")
                case 1: teamSectionView(side: "B")
                default: serviceSettingSection
                }

                if let err = validationError {
                    Section {
                        Label(err, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
        }
    }

    // MARK: Team Section
    @ViewBuilder
    private func teamSectionView(side: String) -> some View {
        let isA = side == "A"
        let nameBinding   = isA ? $teamAName   : $teamBName
        let shortBinding  = isA ? $teamAShort  : $teamBShort
        let colorBinding  = isA ? $teamAColor  : $teamBColor
        let p1Binding     = isA ? $teamAPlayer1 : $teamBPlayer1
        let p2Binding     = isA ? $teamAPlayer2 : $teamBPlayer2
        let opposingPicks = isA
            ? [teamBPlayer1, teamBPlayer2].compactMap { $0 }
            : [teamAPlayer1, teamAPlayer2].compactMap { $0 }

        Section("隊伍資訊") {
            TextField("隊伍名稱", text: nameBinding)
            HStack {
                TextField("縮寫（2–4字）", text: shortBinding)
                    .onChange(of: shortBinding.wrappedValue) { _, new in
                        if new.count > 4 { shortBinding.wrappedValue = String(new.prefix(4)) }
                    }
                ColorPicker("代表色", selection: colorBinding, supportsOpacity: false)
            }
        }

        Section("球員選擇") {
            PlayerPickerRow(label: "球員 1", selection: p1Binding,
                            players: allPlayers, excluding: [p2Binding.wrappedValue] + opposingPicks)
            PlayerPickerRow(label: "球員 2", selection: p2Binding,
                            players: allPlayers, excluding: [p1Binding.wrappedValue] + opposingPicks)
        }
    }

    // MARK: Service Setting Section
    private var serviceSettingSection: some View {
        Group {
            Section("發球方") {
                Picker("發球隊", selection: $servingTeamSide) {
                    Text(teamAName).tag("A" as TeamSide)
                    Text(teamBName).tag("B" as TeamSide)
                }
                .pickerStyle(.segmented)
                .onChange(of: servingTeamSide) { _, _ in
                    servingPlayer   = nil
                    receivingPlayer = nil
                }
            }

            Section("發球員（發球方隊員）") {
                ForEach(servingTeamPlayers) { player in
                    SelectablePlayerRow(
                        player: player,
                        isSelected: servingPlayer?.id == player.id
                    ) { servingPlayer = player }
                }
            }

            Section("接發球員（對方隊員）") {
                ForEach(receivingTeamPlayers) { player in
                    SelectablePlayerRow(
                        player: player,
                        isSelected: receivingPlayer?.id == player.id
                    ) { receivingPlayer = player }
                }
            }

            Section {
                Text("選擇發球方、發球員及接發球員後即可開始比賽。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Toolbar
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("取消") { dismiss() }
        }
        if step > 0 {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { withAnimation { step -= 1 } }) {
                    Image(systemName: "chevron.left")
                }
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            if step < 2 {
                Button("下一步") {
                    if validateStep() { withAnimation { step += 1 } }
                }
            } else {
                Button("開始比賽") { createSession() }
                    .bold()
                    .disabled(!canFinish)
            }
        }
    }

    private var canFinish: Bool {
        servingPlayer != nil && receivingPlayer != nil
    }

    // MARK: Validation
    @discardableResult
    private func validateStep() -> Bool {
        validationError = nil
        switch step {
        case 0:
            guard teamAPlayer1 != nil, teamAPlayer2 != nil else {
                validationError = "請為 A 隊選擇兩位球員"
                return false
            }
            guard teamAShort.trimmingCharacters(in: .whitespaces).count >= 1 else {
                validationError = "請輸入 A 隊縮寫"
                return false
            }
        case 1:
            guard teamBPlayer1 != nil, teamBPlayer2 != nil else {
                validationError = "請為 B 隊選擇兩位球員"
                return false
            }
            guard teamBShort.trimmingCharacters(in: .whitespaces).count >= 1 else {
                validationError = "請輸入 B 隊縮寫"
                return false
            }
        default:
            break
        }
        return true
    }

    // MARK: Create Session
    private func createSession() {
        validationError = nil
        guard let a1 = teamAPlayer1, let a2 = teamAPlayer2,
              let b1 = teamBPlayer1, let b2 = teamBPlayer2,
              let srv = servingPlayer, let rcv = receivingPlayer else {
            validationError = "請完整填寫所有欄位"
            return
        }
        do {
            let colorHexA = teamAColor.toHex() ?? "#FF0000"
            let colorHexB = teamBColor.toHex() ?? "#0000FF"
            let tA = try Team(name: teamAName, shortName: teamAShort,
                              colorHex: colorHexA, player1: a1, player2: a2)
            let tB = try Team(name: teamBName, shortName: teamBShort,
                              colorHex: colorHexB, player1: b1, player2: b2)
            let session = try MatchSession(
                teamA: tA, teamB: tB,
                initialServerTeam: servingTeamSide,
                initialServerPlayerId: srv.id,
                initialReceiverPlayerId: rcv.id
            )
            onSessionCreated(session)
            dismiss()
        } catch {
            validationError = error.localizedDescription
        }
    }
}

// MARK: - PlayerPickerRow
/// 下拉式球員選擇列，自動排除已選球員。
private struct PlayerPickerRow: View {
    let label: String
    @Binding var selection: Player?
    let players: [Player]
    let excluding: [Player?]

    private var available: [Player] {
        let excludeIDs = Set(excluding.compactMap { $0?.id })
        return players.filter { !excludeIDs.contains($0.id) }
    }

    var body: some View {
        Picker(label, selection: $selection) {
            Text("—  未選擇  —").tag(Optional<Player>.none)
            ForEach(available) { p in
                Text("\(p.shortName)  \(p.displayName)").tag(Optional<Player>.some(p))
            }
        }
    }
}

// MARK: - SelectablePlayerRow
private struct SelectablePlayerRow: View {
    let player: Player
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Text("\(player.shortName)  \(player.displayName)")
                    .foregroundStyle(isSelected ? Color.accentColor : .primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .bold()
                }
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Color hex helper
extension Color {
    /// 轉換為 6 位 hex 字串，例如 "#FF3B30"。
    func toHex() -> String? {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return String(format: "#%02X%02X%02X",
                      Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
