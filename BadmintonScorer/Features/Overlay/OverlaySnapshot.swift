import Foundation
import CoreGraphics

// MARK: - OverlaySnapshot
/// OverlayViewModel が 1 UI cycle ごとに生成する値型スナップショット。
/// PreviewOverlayView（SwiftUI）と BurnInRenderer（Core Graphics）が共用する。
struct OverlaySnapshot: Equatable {

    // MARK: Team Labels
    struct TeamInfo: Equatable {
        let shortName: String   // 縮寫，例如 "TA"
        let colorHex: String    // 代表色 hex，例如 "#FF0000"
        let score: Int
        let gamesWon: Int
    }

    let teamA: TeamInfo
    let teamB: TeamInfo

    // MARK: Game / Match State
    let currentGameIndex: Int       // 1-based（第幾局）
    let servingTeam: TeamSide       // "A" 或 "B"
    let serviceCourt: ServiceCourt  // .left / .right

    // MARK: Badges
    let isGamePointA: Bool
    let isGamePointB: Bool
    let isMatchPointA: Bool
    let isMatchPointB: Bool

    // MARK: Phase
    let phase: DerivedMatchState.Phase

    // MARK: Timestamp
    let generatedAt: Date

    // MARK: Factory
    static func from(_ state: DerivedMatchState, session: MatchSession) -> OverlaySnapshot {
        OverlaySnapshot(
            teamA: TeamInfo(
                shortName: session.teamA.shortName,
                colorHex:  session.teamA.colorHex,
                score:     state.scoreA,
                gamesWon:  state.gamesWonA
            ),
            teamB: TeamInfo(
                shortName: session.teamB.shortName,
                colorHex:  session.teamB.colorHex,
                score:     state.scoreB,
                gamesWon:  state.gamesWonB
            ),
            currentGameIndex: state.currentGameIndex,
            servingTeam:  state.servingTeam,
            serviceCourt: state.serviceCourt,
            isGamePointA:  state.isGamePointA,
            isGamePointB:  state.isGamePointB,
            isMatchPointA: state.isMatchPointA,
            isMatchPointB: state.isMatchPointB,
            phase:         state.phase,
            generatedAt:   Date()
        )
    }
}

// MARK: - ServiceCourt (若尚未定義於 Domain)
/// 發球區：左側或右側。
enum ServiceCourt: String, Equatable {
    case left
    case right
}
