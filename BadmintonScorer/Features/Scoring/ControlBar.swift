import SwiftUI

// MARK: - ControlBar (Undo / Pause•Resume / Stop)
/// 共用控制列，最小觸摸目標 44pt。
struct ControlBar: View {
    let canUndo: Bool
    let recordingState: RecordingState
    let onUndo: () -> Void
    let onPauseResume: () -> Void
    let onStop: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            // Undo
            ControlButton(
                icon: "arrow.uturn.backward.circle",
                label: "Undo",
                isEnabled: canUndo && recordingState == .recording
            ) {
                onUndo()
            }

            Spacer()

            // Pause / Resume
            ControlButton(
                icon: recordingState == .paused ? "play.circle.fill" : "pause.circle",
                label: recordingState == .paused ? "Resume" : "Pause",
                isEnabled: recordingState == .recording || recordingState == .paused
            ) {
                onPauseResume()
            }

            // Stop
            ControlButton(
                icon: "stop.circle",
                label: "Stop",
                isEnabled: recordingState == .recording || recordingState == .paused,
                tint: .red
            ) {
                onStop()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

// MARK: - ControlButton
private struct ControlButton: View {
    let icon: String
    let label: String
    let isEnabled: Bool
    var tint: Color = .white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 26))
                Text(label)
                    .font(.system(.caption2, design: .rounded))
            }
            .foregroundStyle(isEnabled ? tint : .white.opacity(0.3))
            .frame(minWidth: 44, minHeight: 44)
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
    }
}
