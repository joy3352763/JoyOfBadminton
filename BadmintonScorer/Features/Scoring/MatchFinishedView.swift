import SwiftUI

// MARK: - MatchFinishedView
/// 比賽結束畫面：顯示絕對贏家 + 局比。
struct MatchFinishedView: View {
    let state: DerivedMatchState
    let session: MatchSession
    let onNewMatch: () -> Void
    let onExit: () -> Void

    private var winnerName: String {
        state.winner == "A" ? session.teamA.name : session.teamB.name
    }
    private var winnerShort: String {
        state.winner == "A" ? session.teamA.shortName : session.teamB.shortName
    }
    private var winnerColor: Color {
        Color(hex: state.winner == "A" ? session.teamA.colorHex : session.teamB.colorHex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // 冠軍圖示
                Image(systemName: "trophy.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(winnerColor)

                VStack(spacing: 8) {
                    Text("　贏家　")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(winnerName)
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(winnerColor)
                }

                // 局比
                HStack(spacing: 32) {
                    ForEach(0..<max(state.gamesWonA, state.gamesWonB, 1), id: \.self) { _ in
                        Image(systemName: "circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }

                Text("\(session.teamA.shortName) \(state.gamesWonA) – \(state.gamesWonB) \(session.teamB.shortName)")
                    .font(.system(.title2, design: .rounded).bold())
                    .foregroundStyle(.white)
                    .monospacedDigit()

                Spacer()

                // 操作按鈕
                VStack(spacing: 12) {
                    Button(action: onNewMatch) {
                        Text("新一場比賽")
                            .font(.body.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(winnerColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Button(action: onExit) {
                        Text("退出")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}
