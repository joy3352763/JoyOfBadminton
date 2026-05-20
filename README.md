# 🏸 JoyOfBadminton

[![CI — Build & Test](https://github.com/joy3352763/JoyOfBadminton/actions/workflows/ci.yml/badge.svg)](https://github.com/joy3352763/JoyOfBadminton/actions/workflows/ci.yml)

iOS 羽球雙打錄影計分 App MVP — 純地端、事件溯源架構。

## 功能概覽

- 雙打計分（三戰兩勝、21 分制、30 分封頂）
- 事件級撤銷（Undo 任意一球）
- 比分即時燒錄進影片（Core Graphics + AVAssetWriter）
- iPhone / iPad 雙介面支援
- 發球區、局點、賽點旗標自動計算

---

## 🟢 MVP 完成！Epic 進度

| Epic | 內容 | 狀態 |
|------|------|------|
| A | Domain Models（Player / Team / MatchSession） | ✅ 完成 |
| B | MatchEngine 規則引擎 | ✅ 完成 |
| C | 單元測試（16 項） | ✅ 完成 |
| D | SwiftUI 賽前 UI | ✅ 完成 |
| E | 計分頁 UI（iPhone / iPad） | ✅ 完成 |
| F | Overlay ViewModel + PreviewOverlay + BurnInRenderer | ✅ 完成 |
| G | RecorderPipeline（AVFoundation） | ✅ 完成 |
| H | 整合驗收（AppComposer + 整合測試） | ✅ 完成 |

**目標測試：24 項**（16 單元 + 8 整合驗收）

---

## 專案架構

```
BadmintonScorer/
├── App/
│   ├── BadmintonScorerApp.swift     # @StateObject AppComposer 進入點
│   ├── AppComposer.swift            # H2: 完整物件圖組裝點
│   ├── AppRouter.swift              # @Observable 導航狀態機
│   └── ContentView.swift            # .setup / .inMatch 切換
├── Domain/
│   ├── Models/
│   │   ├── Player.swift
│   │   ├── Team.swift
│   │   ├── MatchSession.swift
│   │   └── MatchEvent.swift             # TeamSide + ServiceCourt enum + DerivedMatchState
│   ├── Engine/
│   │   └── MatchEngine.swift
│   └── Store/
│       ├── MatchStore.swift             # 注入 RecorderPipeline
│       └── PlayerStore.swift
├── Features/
│   ├── PlayerManagement/            # Epic D1
│   ├── MatchSetup/                  # Epic D2
│   ├── Scoring/                     # Epic E
│   │   ├── AdaptiveScoreView.swift
│   │   ├── iPhoneScoreView.swift
│   │   ├── iPadScoreView.swift
│   │   ├── ScorePanel.swift
│   │   ├── ControlBar.swift
│   │   ├── GameBreakSheet.swift
│   │   ├── MatchFinishedView.swift
│   │   └── RecordingStateBanner.swift
│   ├── Overlay/                     # Epic F
│   │   ├── OverlaySnapshot.swift
│   │   ├── OverlayViewModel.swift       # H2: onSnapshotUpdated hook
│   │   ├── PreviewOverlayView.swift
│   │   └── BurnInRenderer.swift
│   └── Recording/                   # Epic G
│       ├── CameraSession.swift          # G1
│       ├── RecorderPipeline.swift       # G2/G3/G4
│       └── CameraPreviewView.swift
├── Resources/
│   ├── Info.plist                   # 相機/麥克風權限、方向鎖定、Background Audio
│   └── ColorExtensions.swift
BadmintonScorerTests/
└── IntegrationAcceptanceTests.swift  # H1: 8 項整合驗收場景
XCODE_SETUP.md                         # 本機 Build 確認清單
```

---

## 測試覆蓋範圍

### 單元測試（16 項，`MatchEngineTests.swift`）

| 測試組 | 場景 |
|------|---------|
| Model 驗證 | 空名稱、重複球員 |
| 發球權 | 得分方保發 / 換發 |
| 局點 / Deuce | 20:19、20:20、deuce、29:29 封頂 |
| 三戰兩勝 | 正確關比、winner 標記 |
| Undo | 撤銷 PointAwarded / NextGameStarted / 空日誌 |
| rebuildState | 與逐步 apply 一致性 |

### 整合驗收（8 項，`IntegrationAcceptanceTests.swift`）

| 場景 | BDD 參照 |
|------|-----------|
| 全比賽生呼週期（三局兩勝） | §7.2 Feature: 計分規則 |
| 壓力測試（100 球 replay） | §8 H1 |
| rebuildState 冪等性 | §8 H1 |
| Deuce / 30 分封頂邊界 | §7.2 Scenario: 30:29 |
| Undo 鏈（連續 5 次） | §7.2 Feature: 撤銷 |
| RecordingState 狀態機 | §7.3 Scenario: idle→saved |
| Winner 傳遞 | §7.2 Scenario: A 拿 2 局 |
| eventCursor 單調 | §8 H1 |

---

## App 資料流全山

```
[CameraSession]
    │ onFrame(CMSampleBuffer)
    ▼
[RecorderPipeline]
    ├─ currentSnapshot ← [OverlayViewModel.onSnapshotUpdated] ← [MatchStore.state]
    ├─ BurnInRenderer.render(snapshot) → CGImage
    ├─ in-place composite → CVPixelBuffer
    └─ AVAssetWriter.append → .mp4

[MatchStore]
    ├─ awardPoint / undo / startNextGame
    ├─ startRecording / pause / resume / stop → pipeline
    └─ @Published state → [OverlayViewModel] → [PreviewOverlayView]

[AppComposer] — 建立並接線所有物件
    └─ MatchStore + PlayerStore + RecorderPipeline + OverlayViewModel
        └─ .environmentObject() → SwiftUI View Tree

[iPhoneScoreView / iPadScoreView]
    ├─ CameraPreviewView (live preview)
    └─ PreviewOverlayView (transparent canvas overlay)
```

---

## 環境需求

- Xcode 16.3+ / iOS 17.0+ / Swift 5.9+
- Info.plist 已包含：`NSCameraUsageDescription`、`NSMicrophoneUsageDescription`、`NSPhotoLibraryAddUsageDescription`

## CI 設定

使用 **GitHub Actions** 自動在每次 push / PR 執行 `xcodebuild build` + `test`。

### ⚠️ 本機 Build 前先確認（詳見 `XCODE_SETUP.md`）

| 項目 | 目前設定 | 如何確認 |
|------|---------|---------|
| `GENERATE_INFOPLIST_FILE` | `YES`（預設） | 改為 `No` |
| `INFOPLIST_FILE` | 空 | `BadmintonScorer/Resources/Info.plist` |
| `PROJECT_PATH` | `BadmintonScorer/BadmintonScorer.xcodeproj` | Xcode Navigator 檔名 |
| `SCHEME` | `BadmintonScorer` | `xcodebuild -list` |
| Xcode 版本 | `/Applications/Xcode_16.3.app` | `ls /Applications/ \| grep Xcode` |

## 建立 Xcode 專案

1. Xcode → **File → New → Project → iOS App**
2. Product Name: `BadmintonScorer`，Interface: SwiftUI，Include Tests
3. 將此 repo 的 `BadmintonScorer/` 內容拖入對應 Group
4. 完成 `XCODE_SETUP.md` 所列全部打勾項目
5. `⌘B` Build、`⌘U` 執行 24 項測試
