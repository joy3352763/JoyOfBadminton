import SwiftUI

// MARK: - RecordingState (E4)
enum RecordingState: String, Equatable {
    case idle
    case recording
    case paused
    case finalizing
    case saved

    var label: String {
        switch self {
        case .idle:       return ""
        case .recording:  return "REC"
        case .paused:     return "PAUSED"
        case .finalizing: return "儲存中…"
        case .saved:      return "已儲存"
        }
    }

    var color: Color {
        switch self {
        case .idle:       return .clear
        case .recording:  return .red
        case .paused:     return .orange
        case .finalizing: return .yellow
        case .saved:      return .green
        }
    }
}

// MARK: - RecordingStateBanner
struct RecordingStateBanner: View {
    let recordingState: RecordingState
    @State private var dotVisible = true

    var body: some View {
        if recordingState != .idle {
            HStack(spacing: 6) {
                if recordingState == .recording {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .opacity(dotVisible ? 1 : 0.2)
                        .animation(.easeInOut(duration: 0.6).repeatForever(), value: dotVisible)
                        .onAppear { dotVisible.toggle() }
                }
                Text(recordingState.label)
                    .font(.system(.caption, design: .monospaced).bold())
                    .foregroundStyle(recordingState.color)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
        }
    }
}
