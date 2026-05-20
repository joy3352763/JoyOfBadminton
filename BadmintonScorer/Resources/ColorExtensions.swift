import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Color Hex Extensions
/// 全局共用，需要 UIKit（iOS）。
extension Color {

    /// 將 6 位 hex 字串轉換為 SwiftUI Color。
    /// 例： Color(hex: "01696F") 或 Color(hex: "#01696F")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF)         / 255
        self.init(red: r, green: g, blue: b)
    }

    /// 轉換為 6 位大寫 hex 字串，例： "#FF3B30"。
    func toHex() -> String? {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return String(format: "#%02X%02X%02X",
                      Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
