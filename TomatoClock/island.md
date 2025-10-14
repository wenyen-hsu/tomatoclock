# iOS 26 動態島 (Dynamic Island) 與 Live Activities 開發指南

> 基於 Apple 官方 Food Truck 範例項目和 ActivityKit 框架

## 📚 概述

Dynamic Island 是 iPhone 14 Pro 及以上機型的特色功能，通過 Live Activities 和 ActivityKit 框架實現。

### 支援設備
- iPhone 14 Pro / 14 Pro Max
- iPhone 15 Pro / 15 Pro Max
- iPhone 16 Pro / 16 Pro Max
- iOS 16.1 及以上版本

---

## 🏗️ 架構概述

### 必需組件

1. **ActivityAttributes** - 定義 Live Activity 的靜態屬性
2. **ContentState** - 定義 Live Activity 的動態狀態
3. **Widget Extension** - 實現 UI 顯示
4. **主 App** - 請求和管理 Live Activity

---

## 📝 實作步驟

### 1. 配置 Info.plist

#### 主 App Info.plist
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

#### Widget Extension Info.plist
```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.widgetkit-extension</string>
</dict>
<key>NSSupportsLiveActivities</key>
<true/>
<key>NSSupportsLiveActivitiesFrequentUpdates</key>
<true/>
```

### 2. 定義 ActivityAttributes

```swift
import ActivityKit
import Foundation

struct TimerActivityAttributes: ActivityAttributes {
    /// 靜態屬性 - 在 Activity 生命週期中不會改變
    public struct ContentState: Codable, Hashable {
        /// 動態狀態 - 可以通過 update() 更新
        var remainingSeconds: TimeInterval
        var mode: TimerMode
        var state: TimerState
        var displayTime: String
        var timerEndDate: Date  // 用於自動倒數計時
    }

    /// 靜態屬性
    var sessionCount: Int
}
```

### 3. 創建 Live Activity Widget

```swift
import ActivityKit
import WidgetKit
import SwiftUI

struct TimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // 鎖屏顯示
            LockScreenView(context: context)
                .activityBackgroundTint(.white)

        } dynamicIsland: { context in
            // 動態島配置
            DynamicIsland {
                // 展開視圖 - 中央區域
                DynamicIslandExpandedRegion(.center) {
                    ExpandedCenterView(context: context)
                }

                // 展開視圖 - 底部區域
                DynamicIslandExpandedRegion(.bottom) {
                    CountdownView(context: context)
                }

            } compactLeading: {
                // 緊湊模式 - 左側
                Image(systemName: "timer")
                    .foregroundColor(.red)

            } compactTrailing: {
                // 緊湊模式 - 右側（自動倒數計時）
                Text(context.state.timerEndDate, style: .timer)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .monospacedDigit()

            } minimal: {
                // 最小化視圖
                Image(systemName: "timer")
                    .foregroundColor(.red)
            }
            .widgetURL(URL(string: "tomatoclock://focus"))
        }
    }
}
```

### 4. 請求 Live Activity

```swift
import ActivityKit

func startLiveActivity() {
    // 檢查是否啟用 Live Activities
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
        print("Live Activities are not enabled")
        return
    }

    let remaining = currentData.currentRemaining()
    let timerEndDate = Date().addingTimeInterval(remaining)

    // 設定靜態屬性
    let attributes = TimerActivityAttributes(
        sessionCount: sessionManager.currentProgress.completedCount
    )

    // 設定動態狀態
    let contentState = TimerActivityAttributes.ContentState(
        remainingSeconds: remaining,
        mode: currentData.mode,
        state: currentData.state,
        displayTime: remaining.formatAsMMSS(),
        timerEndDate: timerEndDate
    )

    // 請求 Activity
    do {
        let activity = try Activity<TimerActivityAttributes>.request(
            attributes: attributes,
            content: .init(state: contentState, staleDate: nil),
            pushType: nil
        )
        currentActivity = activity
        print("✅ Live Activity started: \(activity.id)")
    } catch {
        print("❌ Failed to start Live Activity: \(error)")
    }
}
```

### 5. 更新 Live Activity

```swift
func updateLiveActivity() {
    guard let activity = currentActivity else { return }

    let remaining = currentData.currentRemaining()
    let timerEndDate = Date().addingTimeInterval(remaining)

    let contentState = TimerActivityAttributes.ContentState(
        remainingSeconds: remaining,
        mode: currentData.mode,
        state: currentData.state,
        displayTime: remaining.formatAsMMSS(),
        timerEndDate: timerEndDate
    )

    Task {
        await activity.update(.init(state: contentState, staleDate: nil))
    }
}
```

### 6. 結束 Live Activity

```swift
func endLiveActivity() {
    guard let activity = currentActivity else { return }

    Task {
        // 立即結束
        await activity.end(nil, dismissalPolicy: .immediate)
        currentActivity = nil
        print("✅ Live Activity ended")

        // 或延遲結束
        // await activity.end(nil, dismissalPolicy: .after(.now + 5))
    }
}
```

---

## 🎨 Dynamic Island 佈局

### 四種展示模式

#### 1. Expanded (展開模式)
```swift
DynamicIsland {
    // Leading Region - 左上區域
    DynamicIslandExpandedRegion(.leading) {
        Image("icon")
    }

    // Trailing Region - 右上區域
    DynamicIslandExpandedRegion(.trailing, priority: 1) {
        Text("狀態")
            .dynamicIsland(verticalPlacement: .belowIfTooWide)
    }

    // Center Region - 中央區域
    DynamicIslandExpandedRegion(.center) {
        VStack {
            Text("標題")
            Spacer()
        }
    }

    // Bottom Region - 底部區域
    DynamicIslandExpandedRegion(.bottom) {
        HStack {
            Button("操作 1") { }
            Button("操作 2") { }
        }
    }
}
```

#### 2. Compact (緊湊模式)
```swift
compactLeading: {
    // 左側圖標
    Image(systemName: "timer")
        .padding(4)
        .background(.red.gradient, in: ContainerRelativeShape())
}

compactTrailing: {
    // 右側文字（自動倒數）
    Text(timerInterval: context.state.timerRange, countsDown: true)
        .monospacedDigit()
        .frame(width: 40)
}
```

#### 3. Minimal (最小化模式)
```swift
minimal: {
    // 單一圖標
    Image(systemName: "timer")
        .padding(4)
        .background(.red.gradient, in: ContainerRelativeShape())
}
```

---

## ⏱️ 自動倒數計時

使用 SwiftUI 的 `.timer` 樣式實現自動倒數：

```swift
// ✅ 推薦：使用 Date 和 .timer 樣式
Text(context.state.timerEndDate, style: .timer)
    .font(.system(size: 28, weight: .bold, design: .rounded))
    .monospacedDigit()

// ❌ 不推薦：使用靜態字串需要手動更新
Text(context.state.displayTime)
```

### Timer Interval 方式

```swift
// 定義時間範圍
let timerRange = Date.now...Date(timeIntervalSinceNow: 300)

// 顯示倒數計時
Text(timerInterval: timerRange, countsDown: true)
    .monospacedDigit()
```

---

## 🎯 最佳實踐

### 1. 性能優化

```swift
// ✅ 使用 staleDate 避免過時的 Activity
let staleDate = Calendar.current.date(
    byAdding: .minute,
    value: 2,
    to: Date()
)

let content = ActivityContent(
    state: contentState,
    staleDate: staleDate
)
```

### 2. 狀態管理

```swift
// 監控所有活動的 Activities
for activity in Activity<TimerActivityAttributes>.activities {
    if activity.attributes.orderID == currentOrderID {
        await activity.end(nil, dismissalPolicy: .immediate)
    }
}
```

### 3. 錯誤處理

```swift
do {
    let activity = try Activity<TimerActivityAttributes>.request(
        attributes: attributes,
        content: content,
        pushType: nil
    )
    currentActivity = activity
} catch let error {
    print("Error requesting live activity: \(error.localizedDescription)")
    // 處理錯誤情況
}
```

### 4. 授權檢查

```swift
// 檢查用戶是否啟用 Live Activities
guard ActivityAuthorizationInfo().areActivitiesEnabled else {
    // 提示用戶啟用 Live Activities
    showLiveActivityAlert()
    return
}
```

---

## 📱 用戶體驗設計

### 內容邊距

```swift
.contentMargins(.trailing, 32, for: .expanded)
.contentMargins([.leading, .top, .bottom], 6, for: .compactLeading)
.contentMargins(.all, 6, for: .minimal)
```

### 動態放置

```swift
.dynamicIsland(verticalPlacement: .belowIfTooWide)
```

### 互動 URL

```swift
.widgetURL(URL(string: "tomatoclock://order/\(orderID)"))
```

---

## 🔍 常見問題

### Q1: Live Activity 不顯示？
**A:** 檢查以下配置：
- Info.plist 中的 `NSSupportsLiveActivities` 設為 `true`
- Widget Extension 的 `NSExtension` 配置正確
- 用戶已在「設定」中啟用 Live Activities

### Q2: 倒數計時不自動更新？
**A:** 使用 `Text(date, style: .timer)` 而非靜態字串

### Q3: App 崩潰在 `willFinishLaunching`？
**A:** 確認 Widget Extension Info.plist 包含完整的 `NSExtension` 配置

### Q4: 安裝時提示 "extensionDictionary must be set"？
**A:** Widget Extension Info.plist 缺少：
```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.widgetkit-extension</string>
</dict>
```

---

## 📚 參考資源

### Apple 官方文檔
- [ActivityKit Documentation](https://developer.apple.com/documentation/activitykit)
- [Live Activities Documentation](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)
- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)

### 範例項目
- [Apple Food Truck Sample](https://github.com/apple/sample-food-truck)
- 展示了 Live Activities、Dynamic Island、Charts 等功能

---

## 🎉 完整範例

查看本專案的實作：
- **TimerActivityAttributes.swift** - Activity 數據模型
- **tomatoclockislandLiveActivity.swift** - Live Activity Widget UI
- **TimerEngine.swift** - Live Activity 生命週期管理

---

**最後更新**: 2025-10-14
**iOS 版本**: iOS 26.0
**Xcode 版本**: 26.0 (17A321)
