import SwiftUI

// MARK: - ScorePanel
/// 共用計分面板，iPhone 與 iPad 都使用。
/// 展示：隊伍名稱、分數、局數、局贏點數、發球指示、局點/賽點 badge。
struct ScorePanel: View {
    let state: DerivedMatchState
    let session: MatchSession
    let onAwardPointA: () -> Void
    let onAwardPointB: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            GameInfoRow(state: state, session: session)
                .padding(.bottom, 8)
            HStack(spacing: 0) {
                TeamScoreButton(
                    teamName: session.teamA.shortName,
                    score: state.scoreA,
                    isServing: state.servingTeam == "A",
                    isGamePoint: state.isGamePointA,
                    isMatchPoint: state.isMatchPointA,
                    colorHex: session.teamA.colorHex,
                    onTap: onAwardPointA
                )
                Divider().frame(width: 1).background(Color.white.opacity(0.3))
                TeamScoreButton(
                    teamName: session.teamB.shortName,
                    score: state.scoreB,
                    isServing: state.servingTeam == "B",
                    isGamePoint: state.isGamePointB,
                    isMatchPoint: state.isMatchPointB,
                    colorHex: session.teamB.colorHex,
                    onTap: onAwardPointB
                )
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - TeamScoreButton
struct TeamScoreButton: View {
    let teamName: String
    let score: Int
    let isServing: Bool
    let isGamePoint: Bool
    let isMatchPoint: Bool
    let colorHex: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Text(teamName)
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundStyle(.white)
                    if isServing {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.yellow)
                    }
                }
                Text("\(score)")
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.3), value: score)
                if isMatchPoint {
                    BadgeView(text: "賽點", color: .orange)
                } else if isGamePoint {
                    BadgeView(text: "局點", color: .yellow)
                } else {
                    BadgeView(text: "", color: .clear).hidden()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .background(Color(hex: colorHex).opacity(0.25))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - GameInfoRow
private struct GameInfoRow: View {
    let state: DerivedMatchState
    let session: MatchSession

    var body: some View {
        Text("第 \(state.currentGameIndex) 局 · \(session.teamA.shortName) \(state.gamesWonA) – \(state.gamesWonB) \(session.teamB.shortName)")
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(.white.opacity(0.85))
            .monospacedDigit()
    }
}

// MARK: - BadgeView
struct BadgeView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(.caption2, design: .rounded).bold())
            .foregroundStyle(.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .clipShape(Capsule())
    }
}
