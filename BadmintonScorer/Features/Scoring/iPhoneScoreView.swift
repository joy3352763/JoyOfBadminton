import SwiftUI

// MARK: - iPhoneScoreView (Epic E1)
struct iPhoneScoreView: View {
    @EnvironmentObject private var matchStore: MatchStore
    let onMatchFinished: () -> Void

    @State private var recordingState: RecordingState = .idle
    @State private var showGameBreakSheet = false
    @State private var showFinishedView = false

    private let haptic = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CameraPreviewPlaceholder().ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    RecordingStateBanner(recordingState: recordingState)
                        .padding(.top, 8)
                        .padding(.trailing, 16)
                }

                Spacer()

                if let session = matchStore.session {
                    ScorePanel(
                        state: matchStore.state,
                        session: session,
                        onAwardPointA: { awardPoint(to: "A") },
                        onAwardPointB: { awardPoint(to: "B") }
                    )
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }

                ControlBar(
                    canUndo: matchStore.canUndo,
                    recordingState: recordingState,
                    onUndo: { haptic.impactOccurred(); matchStore.undo() },
                    onPauseResume: { togglePauseResume() },
                    onStop: { stopRecording() }
                )
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden(true)
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
            matchStore.pauseRecording()
            withAnimation { recordingState = .paused }
        } else if recordingState == .paused {
            matchStore.resumeRecording()
            withAnimation { recordingState = .recording }
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

struct CameraPreviewPlaceholder: View {
    var body: some View {
        ZStack {
            Color.black
            VStack(spacing: 12) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.2))
                Text("相機預覽\n（Epic G 整合後啟用）")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.2))
                    .multilineTextAlignment(.center)
            }
        }
    }
}
