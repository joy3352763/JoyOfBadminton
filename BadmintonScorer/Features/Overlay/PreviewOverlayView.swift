import SwiftUI

// MARK: - PreviewOverlayView  (Epic F2)
/// 透明 SwiftUI overlay，疊加在相機預覽上方。
/// 純 Canvas 繪製，無 UIKit 依賴，尊重 prefers-reduced-motion。
struct PreviewOverlayView: View {

    let snapshot: OverlaySnapshot

    // 外部可控制整體透明度（錄影時提高、暫停時降低）
    var opacity: Double = 1.0

    var body: some View {
        Canvas { ctx, size in
            drawScoreboard(ctx: ctx, size: size)
        }
        .opacity(opacity)
        .allowsHitTesting(false)   // 不攔截觸控
        .accessibilityHidden(true) // 純視覺裝飾
    }

    // MARK: - Draw
    private func drawScoreboard(ctx: GraphicsContext, size: CGSize) {
        let padding: CGFloat  = 12
        let barH: CGFloat     = 56
        let teamW: CGFloat    = (size.width - padding * 3) / 2
        let topY: CGFloat     = size.height - barH - padding

        // ── Team A ──
        drawTeamBlock(
            ctx: ctx,
            rect: CGRect(x: padding, y: topY, width: teamW, height: barH),
            info: snapshot.teamA,
            isServing: snapshot.servingTeam == "A",
            isGamePoint: snapshot.isGamePointA,
            isMatchPoint: snapshot.isMatchPointA,
            alignRight: false
        )

        // ── Divider: current game ──
        let divW: CGFloat = padding
        let divRect = CGRect(x: padding + teamW, y: topY, width: divW, height: barH)
        ctx.fill(Path(divRect), with: .color(.black.opacity(0.55)))
        var gameText = AttributedString("G\(snapshot.currentGameIndex)")
        gameText.font = .system(size: 11, weight: .bold, design: .rounded)
        gameText.foregroundColor = .white
        ctx.draw(Text(gameText), in: divRect)

        // ── Team B ──
        drawTeamBlock(
            ctx: ctx,
            rect: CGRect(x: padding * 2 + teamW, y: topY, width: teamW, height: barH),
            info: snapshot.teamB,
            isServing: snapshot.servingTeam == "B",
            isGamePoint: snapshot.isGamePointB,
            isMatchPoint: snapshot.isMatchPointB,
            alignRight: true
        )
    }

    private func drawTeamBlock(
        ctx: GraphicsContext,
        rect: CGRect,
        info: OverlaySnapshot.TeamInfo,
        isServing: Bool,
        isGamePoint: Bool,
        isMatchPoint: Bool,
        alignRight: Bool
    ) {
        // Background
        let teamColor = Color(hex: info.colorHex).opacity(0.75)
        ctx.fill(Path(roundedRect: rect, cornerRadius: 8), with: .color(teamColor))

        // Score (large)
        var scoreAttr = AttributedString("\(info.score)")
        scoreAttr.font = .system(size: 30, weight: .black, design: .rounded)
        scoreAttr.foregroundColor = .white
        let scoreRect = CGRect(x: rect.midX - 20, y: rect.minY + 4, width: 40, height: 34)
        ctx.draw(Text(scoreAttr), in: scoreRect)

        // Short name + games won
        var nameAttr = AttributedString("\(info.shortName) \(String(repeating: "●", count: info.gamesWon))")
        nameAttr.font = .system(size: 11, weight: .semibold)
        nameAttr.foregroundColor = .white.opacity(0.9)
        let nameRect = CGRect(x: rect.minX + 4, y: rect.maxY - 16, width: rect.width - 8, height: 14)
        ctx.draw(Text(nameAttr), in: nameRect)

        // Serving indicator
        if isServing {
            let dotSize: CGFloat = 8
            let dotX = alignRight ? rect.maxX - dotSize - 4 : rect.minX + 4
            let dotRect = CGRect(x: dotX, y: rect.minY + 4, width: dotSize, height: dotSize)
            ctx.fill(Path(ellipseIn: dotRect), with: .color(.yellow))
        }

        // Badge
        let badgeText: String? = isMatchPoint ? "MP" : isGamePoint ? "GP" : nil
        if let badge = badgeText {
            var badgeAttr = AttributedString(badge)
            badgeAttr.font = .system(size: 9, weight: .heavy)
            badgeAttr.foregroundColor = .black
            let bW: CGFloat = 22
            let bX = alignRight ? rect.minX + 4 : rect.maxX - bW - 4
            let badgeRect = CGRect(x: bX, y: rect.minY + 4, width: bW, height: 14)
            ctx.fill(Path(roundedRect: badgeRect, cornerRadius: 3),
                     with: .color(isMatchPoint ? .red : .yellow))
            ctx.draw(Text(badgeAttr), in: badgeRect)
        }
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    ZStack {
        Color.black
        PreviewOverlayView(
            snapshot: .mock,
            opacity: 1.0
        )
    }
}

extension OverlaySnapshot {
    static var mock: OverlaySnapshot {
        OverlaySnapshot(
            teamA: .init(shortName: "TA", colorHex: "#E53935", score: 20, gamesWon: 1),
            teamB: .init(shortName: "TB", colorHex: "#1E88E5", score: 19, gamesWon: 0),
            currentGameIndex: 2,
            servingTeam: "A",
            serviceCourt: .right,
            isGamePointA: true,
            isGamePointB: false,
            isMatchPointA: false,
            isMatchPointB: false,
            phase: .inGame,
            generatedAt: Date()
        )
    }
}
#endif
