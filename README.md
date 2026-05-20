# 🏸 JoyOfBadminton

[![CI — Build & Test](https://github.com/joy3352763/JoyOfBadminton/actions/workflows/ci.yml/badge.svg)](https://github.com/joy3352763/JoyOfBadminton/actions/workflows/ci.yml)

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
│   ├── BadmintonScorerApp.swift
│   ├── AppRouter.swift
│   └── ContentView.swift
├── Domain/
│   ├── Models/             # Player, Team, MatchSession, MatchEvent, DerivedMatchState
│   ├── Engine/             # MatchEngine
│   └── Store/              # PlayerStore, MatchStore
├── Features/
│   ├── PlayerManagement/   # Epic D1
│   ├── MatchSetup/         # Epic D2
│   ├── Scoring/            # Epic E
│   ├── Overlay/            # Epic F ✔
│   │   ├── OverlaySnapshot.swift
│   │   ├── OverlayViewModel.swift
│   │   ├── PreviewOverlayView.swift
│   │   └── BurnInRenderer.swift
│   └── Recording/          # Epic G（待實作）
└── Resources/
    └── ColorExtensions.swift
```

## Epic 進度

| Epic | 內容 | 狀態 |
|------|------|------|
| A | Domain Models | ✅ 完成 |
| B | MatchEngine 規則引擎 | ✅ 完成 |
| C | 單元測試（16 項） | ✅ 完成 |
| D | SwiftUI 賽前 UI | ✅ 完成 |
| E | 計分頁 UI（iPhone / iPad） | ✅ 完成 |
| F | Overlay ViewModel + 預覽層 + BurnIn | ✅ 完成 |
| G | RecorderPipeline | 🔲 待實作 |
| H | 整合驗收 | 🔲 待實作 |

---

## Epic F 完成度明細

### F1 — OverlaySnapshot ✅

共用値型，對 PreviewOverlay（SwiftUI）和 BurnInRenderer（Core Graphics）提供同一資料源。

| 屬性 | 内容 |
|------|---------|
| `teamA` / `teamB` | `TeamInfo`（shortName、colorHex、score、gamesWon）|
| `currentGameIndex` | 1-based 局數 |
| `servingTeam` / `serviceCourt` | 發球方 + 發球區（left/right）|
| `isGamePointA/B` / `isMatchPointA/B` | 局點 / 賽點旗標 |
| `phase` | `DerivedMatchState.Phase` |
| `from(_:session:)` | 工廠方法，由 DerivedMatchState + MatchSession 建立 |

### F2 — OverlayViewModel ✅

```
MatchStore.state 改變
       ↓ refresh()
  OverlaySnapshot
       ↓
  PreviewOverlayView / BurnInRenderer
```

- `@Observable` — 支援 `@State` + `.onChange` 訂閱
- `refresh()` 公開方法，由 View 在 `.onChange(of: matchStore.state)` 呼叫
- `session == nil` 時 snapshot 為 `nil`，PreviewOverlay 自動隐藏

### F3 — PreviewOverlayView ✅

- 純 **SwiftUI Canvas** 繪製，無 UIKit 依賴
- `.allowsHitTesting(false)` — 不攔截觸控
- `.accessibilityHidden(true)` — 純視覺裝飾
- `opacity` 參數可外控（暫停錄影時可降至 0.5）
- `#Preview` + `OverlaySnapshot.mock` 即時預覽

| 元件 | 說明 |
|------|---------|
| Team block | 隊色底層 + 分數大字 + shortName + gamesWon 圓點 |
| 發球點 | 黃色圓點，發球方顯示 |
| GP / MP badge | 黃色（局點）/ 紅色（賽點），对車對方角 |
| 局數 divider | 中間黑色區塊顯示「 G2 」|

### F4 — BurnInRenderer ✅

- 純 **Core Graphics + CoreText**，無 UIKit / SwiftUI
- `render(snapshot:) -> CGImage?` — 可在任意 queue 呼叫
- 預設畫布 **1920×1080**，`scale` 參數支援 HiDPI
- 所有尺寸相對畫布比例，自適應任意達到分辨率
- 回傳 RGBA premultiplied CGImage，直接 composite 至 `CVPixelBuffer`

---

## App 根路由整合

```
ContentView
├── .setup  → MainTabView
│              ├── PlayerManagementView
│              └── MatchSetupView → onSessionCreated → router.goToMatch()
└── .inMatch → AdaptiveScoreView
                ├── compact → iPhoneScoreView → PreviewOverlayView
                └── regular → iPadScoreView → PreviewOverlayView
                              ↓ onMatchFinished → router.goToSetup()
```

---

## Build 已知修復項目

| # | 問題 | 修復 |
|---|------|---------|
| 1 | `Color(hex:)` 分散定義 | 統一至 `ColorExtensions.swift` |
| 2 | `AppRouter` 缺 `import Observation` | `9cd30aa` |
| 3 | `MatchSetupView.onSessionCreated` 為 `var` | 改為 `let` `1126595` |
| 4 | `ContentView` 語法不一致 | 修正為 `let` 初始化 |
| 5 | `AppRoute.finished` 多餘 case | 移除 |

---

## 環境需求

- Xcode 16.3+ / iOS 17.0+ / Swift 5.9+

## CI 設定

使用 **GitHub Actions** 自動在每次 push / PR 執行 `xcodebuild build` + `test`。

### ⚠️ 需要在 Xcode 中確認（`.github/workflows/ci.yml`）

| 項目 | 目前設定 | 如何確認 |
|------|---------|---------|
| `PROJECT_PATH` | `BadmintonScorer/BadmintonScorer.xcodeproj` | Xcode Navigator 中 `.xcodeproj` 檔名 |
| `SCHEME` | `BadmintonScorer` | scheme 下拉 或 `xcodebuild -list` |
| Xcode 版本 | `/Applications/Xcode_16.3.app` | `ls /Applications/ \| grep Xcode` |

```bash
xcodebuild -list -project BadmintonScorer/BadmintonScorer.xcodeproj
```
