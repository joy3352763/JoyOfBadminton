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

## Epic 進度

| Epic | 內容 | 狀態 |
|------|------|------|
| A | Domain Models（Player / Team / MatchSession） | ✅ 完成 |
| B | MatchEngine 規則引擎 | ✅ 完成 |
| C | 單元測試（16 項） | ✅ 完成 |
| D | SwiftUI 賽前 UI | ✅ 完成 |
| E | 計分頁 UI（iPhone / iPad） | ✅ 完成 |
| F | Overlay ViewModel + PreviewOverlay + BurnInRenderer | ✅ 完成 |
| G | RecorderPipeline（AVFoundation） | ✅ 完成 |
| H | 整合驗收 | 🔲 待執行 |

---

## 專案架構

```
BadmintonScorer/
├── App/
│   ├── BadmintonScorerApp.swift
│   ├── AppRouter.swift          # @Observable 導航狀態機
│   └── ContentView.swift        # .setup / .inMatch 切換
├── Domain/
│   ├── Models/
│   │   ├── Player.swift
│   │   ├── Team.swift
│   │   ├── MatchSession.swift
│   │   └── MatchEvent.swift         # TeamSide + ServiceCourt enum + DerivedMatchState
│   ├── Engine/
│   │   └── MatchEngine.swift
│   └── Store/
│       ├── MatchStore.swift         # 注入 RecorderPipeline
│       └── PlayerStore.swift
├── Features/
│   ├── PlayerManagement/        # Epic D1
│   ├── MatchSetup/              # Epic D2
│   ├── Scoring/                 # Epic E
│   │   ├── AdaptiveScoreView.swift
│   │   ├── iPhoneScoreView.swift
│   │   ├── iPadScoreView.swift
│   │   ├── ScorePanel.swift
│   │   ├── ControlBar.swift
│   │   ├── GameBreakSheet.swift
│   │   ├── MatchFinishedView.swift
│   │   └── RecordingStateBanner.swift
│   ├── Overlay/                 # Epic F
│   │   ├── OverlaySnapshot.swift
│   │   ├── OverlayViewModel.swift
│   │   ├── PreviewOverlayView.swift
│   │   └── BurnInRenderer.swift
│   └── Recording/               # Epic G
│       ├── CameraSession.swift      # G1
│       ├── RecorderPipeline.swift   # G2/G3/G4
│       └── CameraPreviewView.swift  # UIViewRepresentable
└── Resources/
    └── ColorExtensions.swift
```

---

## Epic G 完成度明細

### G1 — CameraSession ✅

| 功能 | 說明 |
|------|---------|
| `requestAccessAndConfigure(completion:)` | 請求相機權限、設置 Session |
| `start()` / `stop()` | Session 生呼週期，在內部 sessionQ 執行 |
| `onFrame` / `onAudio` | `CMSampleBuffer` 回呼閃結 |
| 1920×1080 H.264 | `hd1920x1080` preset，`.landscapeRight` |
| `makePreviewLayer()` | 回傳 `AVCaptureVideoPreviewLayer` 供 `CameraPreviewView` |

### G2 / G3 — RecorderPipeline ✅

| 功能 | 說明 |
|------|---------|
| `startRecording()` | 建立 `AVAssetWriter`、啟動相機 Session |
| Video track | H.264 1920×1080、10 Mbps、real-time |
| Audio track | AAC 44.1 kHz stereo 128 kbps |
| Overlay composite | `BurnInRenderer.render()` → in-place 将 CGImage 燒錄入 `CVPixelBuffer` |
| `currentSnapshot` | `OverlayViewModel` 每幀更新此屬性，RecorderPipeline 在 frame callback 讀取 |

### G4 — RecordingState 狀態機 ✅

```
idle → recording ⇄ paused → finalizing → saved(url) / failed(message)
```

| 方法 | 前置狀態 | 結果 |
|------|-----------|------|
| `startRecording()` | `.idle` | `.recording` |
| `pauseRecording()` | `.recording` | `.paused` |
| `resumeRecording()` | `.paused` | `.recording` |
| `stopRecording()` | `.recording` / `.paused` | `.finalizing` → `.saved` |

### CameraPreviewView ✅

`UIViewRepresentable` 包裝 `AVCaptureVideoPreviewLayer`，取代 Epic E 的 `CameraPreviewPlaceholder`。

---

## Domain 層權限調整

| 變更 | 詳情 |
|------|---------|
| `ServiceCourt` 將為 `String` → `enum` | 移至 `MatchEvent.swift`，Engine / Overlay 共用 |
| `DerivedMatchState.serviceCourt` | 由 `String` 升級為 `ServiceCourt`（`.left` / `.right`） |
| `OverlaySnapshot.swift` | 移除重複的 `ServiceCourt` 定義 |

---

## App 資料流全山

```
[CameraSession]
    │ onFrame(CMSampleBuffer)
    ▼
[RecorderPipeline]
    ├─ currentSnapshot ← [OverlayViewModel] ← [MatchStore.state]
    ├─ BurnInRenderer.render(snapshot) → CGImage
    ├─ in-place composite → CVPixelBuffer
    └─ AVAssetWriter.append → .mp4

[MatchStore]
    ├─ awardPoint / undo / startNextGame
    ├─ startRecording / pause / resume / stop → pipeline
    └─ @Published state → [OverlayViewModel] → [PreviewOverlayView]

[iPhoneScoreView / iPadScoreView]
    ├─ CameraPreviewView (live preview)
    └─ PreviewOverlayView (transparent canvas overlay)
```

---

## Build 已知修復項目

| # | 問題 | 修復 |
|---|------|---------|
| 1 | `Color(hex:)` 分散定義 | 統一至 `ColorExtensions.swift` |
| 2 | `AppRouter` 缺 `import Observation` | `9cd30aa` |
| 3 | `MatchSetupView.onSessionCreated` 為 `var` | 改為 `let` `1126595` |
| 4 | `AppRoute.finished` 多餘 case | 移除 |
| 5 | `ServiceCourt` 重複定義 | 升級至 Domain `MatchEvent.swift` `9ffd70a` |

---

## 環境需求

- Xcode 16.3+ / iOS 17.0+ / Swift 5.9+
- Info.plist 需要加入：
  - `NSCameraUsageDescription`
  - `NSMicrophoneUsageDescription`

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

## 建立 Xcode 專案

1. Xcode → **File → New → Project → iOS App**
2. Product Name: `BadmintonScorer`，Interface: SwiftUI，Include Tests
3. 將此 repo 的 `BadmintonScorer/` 內容拖入對應 Group
4. Info.plist 加入 `NSCameraUsageDescription`、`NSMicrophoneUsageDescription`
5. `⌘B` Build、`⌘U` 執行測試
