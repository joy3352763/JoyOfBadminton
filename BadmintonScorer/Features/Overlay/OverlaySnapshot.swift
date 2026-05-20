import Foundation

// MARK: - OverlaySnapshot
/// OverlayViewModel 「1 UI cycle」生成的共用快照。
/// PreviewOverlayView (SwiftUI) 與 BurnInRenderer (Core Graphics) 共用。
/// ServiceCourt 定義於 Domain/Models/MatchEvent.swift。
struct OverlaySnapshot: Equatable {

    struct TeamInfo: Equatable {
        let shortName: String
        let colorHex:  String
        let score:     Int
        let gamesWon:  Int
    }

    let teamA: TeamInfo
    let teamB: TeamInfo
    let currentGameIndex: Int
    let servingTeam:   TeamSide
    let serviceCourt:  ServiceCourt
    let isGamePointA:  Bool
    let isGamePointB:  Bool
    let isMatchPointA: Bool
    let isMatchPointB: Bool
    let phase:         DerivedMatchState.Phase
    let generatedAt:   Date

    // MARK: Factory
    static func from(_ state: DerivedMatchState, session: MatchSession) -> OverlaySnapshot {
        OverlaySnapshot(
            teamA: TeamInfo(shortName: session.teamA.shortName,
                            colorHex:  session.teamA.colorHex,
                            score:     state.scoreA,
                            gamesWon:  state.gamesWonA),
            teamB: TeamInfo(shortName: session.teamB.shortName,
                            colorHex:  session.teamB.colorHex,
                            score:     state.scoreB,
                            gamesWon:  state.gamesWonB),
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
