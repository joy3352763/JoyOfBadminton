import SwiftUI

// MARK: - iPadScoreView (Epic E2)
struct iPadScoreView: View {
    @EnvironmentObject private var matchStore: MatchStore
    let onMatchFinished: () -> Void

    @State private var recordingState: RecordingState = .idle
    @State private var showGameBreakSheet = false
    @State private var showFinishedView = false

    private let haptic = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                CameraPreviewPlaceholder()
                RecordingStateBanner(recordingState: recordingState)
                    .padding(16)
            }
            .frame(maxWidth: .infinity)

            Divider()

            VStack(spacing: 0) {
                if let session = matchStore.session {
                    ScorePanel(
                        state: matchStore.state,
                        session: session,
                        onAwardPointA: { awardPoint(to: "A") },
                        onAwardPointB: { awardPoint(to: "B") }
                    )
                    .padding(16)
                }
                Spacer()
                ControlBar(
                    canUndo: matchStore.canUndo,
                    recordingState: recordingState,
                    onUndo: { haptic.impactOccurred(); matchStore.undo() },
                    onPauseResume: { togglePauseResume() },
                    onStop: { stopRecording() }
                )
            }
            .frame(width: 360)
            .background(Color(.systemBackground))
        }
        .ignoresSafeArea()
        .onAppear { startRecording() }
        .onChange(of: matchStore.state.phase) { _, phase in handlePhaseChange(phase) }
        .sheet(isPresented: $showGameBreakSheet) {
            if let session = matchStore.session {
                GameBreakSheet(session: session, state: matchStore.state) { servingTeam in
                    matchStore.startNextGame(servingTeam: servingTeam)
                    showGameBreakSheet = false
                }
            }
        }
        .fullScreenCover(isPresented: $showFinishedView) {
            if let session = matchStore.session {
                MatchFinishedView(
                    state: matchStore.state,
                    session: session,
                    onNewMatch: { showFinishedView = false; onMatchFinished() },
                    onExit:     { showFinishedView = false; onMatchFinished() }
                )
            }
        }
    }

    private func startRecording() {
        guard recordingState == .idle else { return }
        matchStore.startRecording()
        withAnimation { recordingState = .recording }
    }

    private func awardPoint(to team: TeamSide) {
        guard matchStore.state.phase == .inGame else { return }
        haptic.impactOccurred()
        matchStore.awardPoint(to: team)
    }

    private func togglePauseResume() {
        if recordingState == .recording {
            matchStore.pauseRecording(); withAnimation { recordingState = .paused }
        } else if recordingState == .paused {
            matchStore.resumeRecording(); withAnimation { recordingState = .recording }
        }
    }

    private func stopRecording() {
        matchStore.stopRecording()
        withAnimation { recordingState = .finalizing }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { recordingState = .saved }
        }
    }

    private func handlePhaseChange(_ phase: DerivedMatchState.Phase) {
        switch phase {
        case .gameBreak: showGameBreakSheet = true
        case .finished:  showFinishedView  = true
        default: break
        }
    }
}
