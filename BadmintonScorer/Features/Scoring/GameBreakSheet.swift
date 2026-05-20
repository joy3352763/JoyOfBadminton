import SwiftUI

// MARK: - GameBreakSheet
/// 局間中斷：顯示局結果並選擇下一局發球隊。
struct GameBreakSheet: View {
    let session: MatchSession
    let state: DerivedMatchState
    let onContinue: (TeamSide) -> Void

    @State private var selectedServingTeam: TeamSide = "A"

    private var gameWinner: String {
        // 上一局贏家為局贏點多的一方
        state.gamesWonA > state.gamesWonB
            ? session.teamA.shortName
            : session.teamB.shortName
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // 局結果
                VStack(spacing: 8) {
                    Text("第 \(state.currentGameIndex) 局結束")
                        .font(.title2.bold())
                    HStack(spacing: 24) {
                        VStack {
                            Text(session.teamA.shortName)
                                .font(.headline)
                                .foregroundStyle(Color(hex: session.teamA.colorHex))
                            Text("\(state.scoreA)")
                                .font(.system(size: 48, weight: .black, design: .rounded))
                        }
                        Text("–")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        VStack {
                            Text(session.teamB.shortName)
                                .font(.headline)
                                .foregroundStyle(Color(hex: session.teamB.colorHex))
                            Text("\(state.scoreB)")
                                .font(.system(size: 48, weight: .black, design: .rounded))
                        }
                    }
                    Text("局贏隊伍：\(gameWinner)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // 選擇下一局發球方
                VStack(alignment: .leading, spacing: 12) {
                    Text("選擇下一局發球方")
                        .font(.headline)
                    Picker("發球方", selection: $selectedServingTeam) {
                        Text(session.teamA.shortName).tag("A" as TeamSide)
                        Text(session.teamB.shortName).tag("B" as TeamSide)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)

                Button(action: { onContinue(selectedServingTeam) }) {
                    Text("開始第 \(state.currentGameIndex + 1) 局")
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("局間休息")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()
        }
    }
}
