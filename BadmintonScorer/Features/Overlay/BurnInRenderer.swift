import CoreGraphics
import CoreText
import Foundation

// MARK: - BurnInRenderer  (Epic F3)
/// 純 Core Graphics 實作，將 OverlaySnapshot 燒錄為 CGImage。
/// 無 UIKit / SwiftUI 依賴，可在任意 DispatchQueue 呼叫。
///
/// 使用方式：
/// ```swift
/// let renderer = BurnInRenderer(canvasSize: CGSize(width: 1920, height: 1080))
/// let cgImage  = renderer.render(snapshot: snapshot)
/// // 將 cgImage composite 至 CVPixelBuffer 後交給 AVAssetWriterInputPixelBufferAdaptor
/// ```
final class BurnInRenderer {

    // MARK: Config
    let canvasSize: CGSize
    let scale: CGFloat          // 通常 1.0（pixel-exact for video）

    // MARK: Layout Constants（相對於 1920×1080）
    private var W: CGFloat { canvasSize.width }
    private var H: CGFloat { canvasSize.height }
    private var pad: CGFloat   { W * 0.012 }    // ~23 pt @ 1920
    private var barH: CGFloat  { H * 0.10 }     // ~108 pt @ 1080
    private var teamW: CGFloat { (W - pad * 3) / 2 }
    private var topY: CGFloat  { H - barH - pad }

    // MARK: Init
    init(canvasSize: CGSize = CGSize(width: 1920, height: 1080), scale: CGFloat = 1.0) {
        self.canvasSize = canvasSize
        self.scale = scale
    }

    // MARK: Public API
    /// 在呼叫端的 queue 上同步執行，回傳透明背景的 CGImage（RGBA）。
    /// 回傳 nil 僅在 context 建立失敗時發生。
    func render(snapshot: OverlaySnapshot) -> CGImage? {
        let w = Int(canvasSize.width  * scale)
        let h = Int(canvasSize.height * scale)
        guard w > 0, h > 0 else { return nil }

        guard let ctx = CGContext(
            data: nil,
            width: w, height: h,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        // Core Graphics 預設原點在左下角；翻轉至左上角
        ctx.translateBy(x: 0, y: CGFloat(h))
        ctx.scaleBy(x: scale, y: -scale)

        drawScoreboard(ctx: ctx, snapshot: snapshot)

        return ctx.makeImage()
    }

    // MARK: - Draw Scoreboard
    private func drawScoreboard(ctx: CGContext, snapshot: OverlaySnapshot) {

        // ── Team A ──
        drawTeamBlock(
            ctx: ctx,
            rect: CGRect(x: pad, y: topY, width: teamW, height: barH),
            info: snapshot.teamA,
            isServing: snapshot.servingTeam == "A",
            isGamePoint: snapshot.isGamePointA,
            isMatchPoint: snapshot.isMatchPointA,
            alignRight: false
        )

        // ── Divider: game index ──
        let divRect = CGRect(x: pad + teamW, y: topY, width: pad, height: barH)
        ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.6))
        ctx.fill(divRect)
        drawText(
            ctx: ctx,
            text: "G\(snapshot.currentGameIndex)",
            rect: divRect,
            fontSize: barH * 0.22,
            weight: .bold,
            color: CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        )

        // ── Team B ──
        drawTeamBlock(
            ctx: ctx,
            rect: CGRect(x: pad * 2 + teamW, y: topY, width: teamW, height: barH),
            info: snapshot.teamB,
            isServing: snapshot.servingTeam == "B",
            isGamePoint: snapshot.isGamePointB,
            isMatchPoint: snapshot.isMatchPointB,
            alignRight: true
        )
    }

    // MARK: - Draw Team Block
    private func drawTeamBlock(
        ctx: CGContext,
        rect: CGRect,
        info: OverlaySnapshot.TeamInfo,
        isServing: Bool,
        isGamePoint: Bool,
        isMatchPoint: Bool,
        alignRight: Bool
    ) {
        // Background — parse colorHex with alpha 0.75
        if let bgColor = cgColor(hex: info.colorHex, alpha: 0.75) {
            ctx.setFillColor(bgColor)
        } else {
            ctx.setFillColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.75))
        }
        fillRoundedRect(ctx: ctx, rect: rect, radius: barH * 0.12)

        // Score (large)
        let scoreRect = CGRect(
            x: rect.midX - barH * 0.45,
            y: rect.minY + barH * 0.05,
            width: barH * 0.9,
            height: barH * 0.65
        )
        drawText(
            ctx: ctx,
            text: "\(info.score)",
            rect: scoreRect,
            fontSize: barH * 0.58,
            weight: .black,
            color: CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        )

        // Short name + games won bullets
        let bullets = String(repeating: "●", count: info.gamesWon)
        let nameStr = bullets.isEmpty ? info.shortName : "\(info.shortName) \(bullets)"
        let nameRect = CGRect(
            x: rect.minX + barH * 0.08,
            y: rect.maxY - barH * 0.30,
            width: rect.width - barH * 0.16,
            height: barH * 0.26
        )
        drawText(
            ctx: ctx,
            text: nameStr,
            rect: nameRect,
            fontSize: barH * 0.22,
            weight: .semibold,
            color: CGColor(red: 1, green: 1, blue: 1, alpha: 0.92)
        )

        // Serving indicator (yellow dot)
        if isServing {
            let dotR = barH * 0.09
            let dotX = alignRight ? rect.maxX - dotR * 2 - barH * 0.04
                                  : rect.minX + barH * 0.04
            let dotRect = CGRect(x: dotX, y: rect.minY + barH * 0.06,
                                 width: dotR * 2, height: dotR * 2)
            ctx.setFillColor(CGColor(red: 1, green: 0.92, blue: 0, alpha: 1))
            ctx.fillEllipse(in: dotRect)
        }

        // Badge (GP / MP)
        let badgeText: String? = isMatchPoint ? "MP" : isGamePoint ? "GP" : nil
        if let badge = badgeText {
            let bW = barH * 0.38
            let bH = barH * 0.26
            let bX = alignRight ? rect.minX + barH * 0.04
                                : rect.maxX - bW - barH * 0.04
            let badgeRect = CGRect(x: bX, y: rect.minY + barH * 0.06, width: bW, height: bH)
            let badgeColor = isMatchPoint
                ? CGColor(red: 0.85, green: 0.1, blue: 0.1, alpha: 1)
                : CGColor(red: 1,    green: 0.82, blue: 0,   alpha: 1)
            ctx.setFillColor(badgeColor)
            fillRoundedRect(ctx: ctx, rect: badgeRect, radius: bH * 0.2)
            drawText(
                ctx: ctx,
                text: badge,
                rect: badgeRect,
                fontSize: bH * 0.68,
                weight: .heavy,
                color: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
            )
        }
    }

    // MARK: - CG Helpers

    private func fillRoundedRect(ctx: CGContext, rect: CGRect, radius: CGFloat) {
        let path = CGMutablePath()
        path.addRoundedRect(in: rect, cornerWidth: radius, cornerHeight: radius)
        ctx.addPath(path)
        ctx.fillPath()
    }

    /// CoreText ベースのテキスト描画（center alignment）
    private func drawText(
        ctx: CGContext,
        text: String,
        rect: CGRect,
        fontSize: CGFloat,
        weight: CTFontWeight,
        color: CGColor
    ) {
        let font = CTFontCreateWithName(
            "SF Pro Rounded" as CFString, fontSize, nil
        )
        let boldFont: CTFont
        let traits = CTFontCopyTraits(font)
        var dict: [CFString: Any] = [
            kCTFontSizeAttribute: fontSize
        ]
        // Map CTFontWeight to symbolic traits
        let weightMap: [(CTFontWeight, CFStringRef)] = [
            (.black,    "Black"),
            (.heavy,    "Heavy"),
            (.bold,     "Bold"),
            (.semibold, "Semibold"),
            (.medium,   "Medium")
        ]
        let suffix = weightMap.first { $0.0.rawValue == weight.rawValue }?.1 ?? ("Regular" as CFStringRef)
        let fontName = "\("SF Pro Rounded")-\(suffix)" as CFString
        boldFont = CTFontCreateWithName(fontName, fontSize, nil)
        _ = traits
        _ = dict

        let attrs: [CFString: Any] = [
            kCTFontAttributeName: boldFont,
            kCTForegroundColorAttributeName: color
        ]
        let attrStr = CFAttributedStringCreate(
            kCFAllocatorDefault,
            text as CFString,
            attrs as CFDictionary
        )!
        let line = CTLineCreateWithAttributedString(attrStr)
        let lineBounds = CTLineGetBoundsWithOptions(line, [])

        // Center in rect
        let x = rect.midX - lineBounds.width / 2
        let y = rect.midY - lineBounds.height / 2 + lineBounds.maxY - lineBounds.height

        ctx.saveGState()
        ctx.textPosition = CGPoint(x: x, y: rect.maxY - (y - rect.minY) - lineBounds.height)
        CTLineDraw(line, ctx)
        ctx.restoreGState()
    }

    // MARK: - Color Helper
    private func cgColor(hex: String, alpha: CGFloat) -> CGColor? {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard h.count == 6 else { return nil }
        var value: UInt64 = 0
        Scanner(string: h).scanHexInt64(&value)
        let r = CGFloat((value >> 16) & 0xFF) / 255
        let g = CGFloat((value >>  8) & 0xFF) / 255
        let b = CGFloat(value         & 0xFF) / 255
        return CGColor(red: r, green: g, blue: b, alpha: alpha)
    }
}

// MARK: - CTFontWeight raw value shim
/// CTFontWeight 本身是 struct，直接比較 rawValue。
extension CTFontWeight {
    static let heavy = CTFontWeight(rawValue: 0.56)
    static let semibold = CTFontWeight(rawValue: 0.23)
    static let `black` = CTFontWeight(rawValue: 0.62)
}
