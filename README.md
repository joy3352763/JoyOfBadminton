# 🏸 JoyOfBadminton

iOS 羽球雙打錄影計分 App MVP — 純地端、事件溯源架構。

## 功能概覽

- 雙打計分（三戰兩勝、21 分制、30 分封頂）
- 事件級撤銷（Undo 任意一球）
- 比分即時燒錄進影片（Core Graphics + AVAssetWriter）
- iPhone / iPad 雙介面支援
- 發球區、局點、賽點旗標自動計算

## 專案架構

```
BadmintonScorer/
├── App/                    # 入口、根路由
├── Domain/
│   ├── Models/             # Player, Team, MatchSession, MatchEvent, DerivedMatchState
│   ├── Engine/             # MatchEngine（純函數規則引擎）
│   └── Store/              # PlayerStore, MatchStore（ObservableObject）
├── Features/
│   ├── PlayerManagement/   # Epic D1
│   ├── MatchSetup/         # Epic D2
│   ├── Scoring/            # Epic E（iPhone / iPad）
│   ├── Overlay/            # Epic F（預覽疊加層）
│   └── Recording/          # Epic G（AVFoundation 錄影）
└── Resources/
```

## Epic 進度

| Epic | 內容 | 狀態 |
|------|------|------|
| A | Domain Models | ✅ 完成 |
| B | MatchEngine 規則引擎 | ✅ 完成 |
| C | 單元測試（45 項） | ✅ 完成 |
| D | SwiftUI 賽前 UI | 🔲 待實作 |
| E | 計分頁 UI | 🔲 待實作 |
| F | Overlay ViewModel | 🔲 待實作 |
| G | RecorderPipeline | 🔲 待實作 |
| H | 整合驗收 | 🔲 待實作 |

## 環境需求

- Xcode 15+
- iOS 16.0+
- Swift 5.9+

## 建立 Xcode 專案

1. Xcode → **File → New → Project → iOS App**
2. Product Name: `BadmintonScorer`，Interface: SwiftUI，Include Tests
3. 將此 repo 的 `BadmintonScorer/` 資料夾內容拖入對應 Group
4. `⌘B` Build、`⌘U` 執行測試
