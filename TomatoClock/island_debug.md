# Dynamic Island 實作問題診斷與修正記錄

**日期**: 2025-10-17
**狀態**: ✅ 已解決

## 問題描述

初始問題：TomatoClock app 的 Dynamic Island 功能完全無法顯示。

## 診斷與修正過程

### 問題 1: Widget Extension Target 缺失

**錯誤訊息**:
```
❌ [Live Activity] Failed to start: unsupportedTarget
   - Error details: The operation couldn't be completed. Target does not include
```

**診斷**:
- 檢查 project.pbxproj 發現只有 `tomatoclockislandExtension` scheme，沒有對應的 target
- Widget Extension 必須是一個獨立的 **Target**，不能只是 scheme

**解決方案**:
1. 在 Xcode 中：File > New > Target
2. 選擇 "Widget Extension"
3. Product Name: `tomatoclockislandExtension`
4. 確認創建後在 project.pbxproj 中有 `PBXNativeTarget` section

**修改文件**: `TomatoClock.xcodeproj/project.pbxproj`

---

### 問題 2: Build Settings 配置缺失

**診斷**:
Widget Extension target 需要特定的 Build Settings 配置才能正常工作。

**解決方案**:
在 `project.pbxproj` 的 widget target build settings 中配置：

```
INFOPLIST_FILE = tomatoclockisland/IslandInfo.plist;
GENERATE_INFOPLIST_FILE = NO;
CODE_SIGN_ENTITLEMENTS = tomatoclockisland/tomatoclockisland.entitlements;
IPHONEOS_DEPLOYMENT_TARGET = 16.1;
PRODUCT_BUNDLE_IDENTIFIER = "tomato-clock.TomatoClock.tomatoclockisland";
```

**修改文件**: `TomatoClock.xcodeproj/project.pbxproj` (lines 398-417)

---

### 問題 3: 共享類型無法訪問

**錯誤訊息**:
```
Cannot find type 'TimerState' in scope
Cannot find type 'TimerMode' in scope
```

**診斷**:
- `TimerActivityAttributes.swift` 使用了 `TimerMode` 和 `TimerState` 枚舉
- 這些文件只屬於主 app target，widget extension 無法訪問

**解決方案**:
在 project.pbxproj 中添加 target membership exceptions：

```xml
membershipExceptions = (
    Core/Models/TimerMode.swift,
    Core/Models/TimerState.swift,
);
target = 28CEC0E52EA148F6007420DF /* tomatoclockislandExtension */;
```

**修改文件**: `TomatoClock.xcodeproj/project.pbxproj` (lines 63-70)

---

### 問題 4: SwiftUI Preview 語法錯誤

**錯誤訊息**:
```
Cannot use explicit 'return' statement in the body of result builder 'ViewBuilder'
```

**診斷**:
SwiftUI Preview blocks 使用 @ViewBuilder，不能使用顯式 return 語句。

**解決方案**:
移除所有 Preview 代碼中的 `return` 關鍵字，或完全刪除無法運行的 Preview。

**修改文件**: `tomatoclockisland/TimerLiveActivityWidget.swift`

---

### 問題 5: DynamicIsland 類型不匹配

**錯誤訊息**:
```
Cannot convert value of type 'some View' to closure result type 'DynamicIsland'
static method 'buildExpression' requires that 'DynamicIsland' conform to 'View'
```

**診斷**:
`dynamicIsland` 閉包必須直接返回 `DynamicIsland` 結構，不能返回一個包裝 DynamicIsland 的 View。

**錯誤寫法**:
```swift
} dynamicIsland: { context in
    TimerDynamicIsland(context: context)  // ❌ 返回 View
}

private struct TimerDynamicIsland: View {
    var body: some View {
        DynamicIsland { ... }
    }
}
```

**正確寫法**:
```swift
} dynamicIsland: { context in
    let snapshot = TimerIslandSnapshot(context: context)
    return DynamicIsland {  // ✅ 直接返回 DynamicIsland
        DynamicIslandExpandedRegion(.leading) { ... }
        DynamicIslandExpandedRegion(.center) { ... }
        // ...
    } compactLeading: { ... }
    compactTrailing: { ... }
    minimal: { ... }
    .keylineTint(snapshot.accentColor)
}
```

**修改文件**: `tomatoclockisland/TimerLiveActivityWidget.swift` (lines 19-87)

---

### 問題 6: Info.plist 包含不兼容的鍵

**錯誤訊息**:
```
Appex bundle defines either an NSExtensionMainStoryboard or NSExtensionPrincipalClass key,
which is not allowed for the extension point com.apple.widgetkit-extension
```

**診斷**:
- 現代 WidgetKit 使用 `@main` annotation
- `NSExtensionPrincipalClass` 是舊版 extension 的配置，不兼容

**解決方案**:
從 `IslandInfo.plist` 中移除：
- `NSExtensionPrincipalClass`
- `NSExtensionAttributes`

只保留：
```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.widgetkit-extension</string>
</dict>
```

**修改文件**: `tomatoclockisland/IslandInfo.plist` (lines 23-27)

---

### 問題 7: 缺少 Dynamic Island 支持鍵

**錯誤訊息**:
Widget 可以 build 和運行，但 Dynamic Island 仍然不顯示。

**診斷**:
即使 Live Activities 啟用，如果缺少 `NSSupportsLiveActivitiesOnDynamicIsland` 鍵，iOS 會忽略 dynamicIsland 閉包的內容，只在鎖定螢幕顯示 Live Activity。

**解決方案**:
在 `IslandInfo.plist` 中添加：

```xml
<key>NSSupportsLiveActivities</key>
<true/>
<key>NSSupportsLiveActivitiesFrequentUpdates</key>
<true/>
<key>NSSupportsLiveActivitiesOnDynamicIsland</key>  <!-- 關鍵！ -->
<true/>
```

**修改文件**: `tomatoclockisland/IslandInfo.plist` (lines 28-33)

---

### 問題 8: 主 App 缺少 Live Activities 支持

**錯誤訊息**:
```
❌ [Live Activity] Failed to start: unsupportedTarget
   - Error details: Target does not include NSSupportsLiveActivities plist key
```

**診斷**:
- 主 app 使用自動生成的 Info.plist (`GENERATE_INFOPLIST_FILE = YES`)
- 手動編輯的 `AppInfo.plist` 沒有被使用
- 需要在 Build Settings 中通過 `INFOPLIST_KEY_*` 添加鍵值

**解決方案**:
在 project.pbxproj 的主 app target build settings 中添加（Debug 和 Release 都要）：

```
INFOPLIST_KEY_NSSupportsLiveActivities = YES;
INFOPLIST_KEY_NSSupportsLiveActivitiesOnDynamicIsland = YES;
```

**修改文件**: `TomatoClock.xcodeproj/project.pbxproj` (lines 586-587, 618-619)

**驗證方法**:
檢查 build 產物：
```bash
plutil -p "Debug-iphoneos/TomatoClock.app/Info.plist" | grep -i "live"
```

應該看到：
```
"NSSupportsLiveActivities" => true
"NSSupportsLiveActivitiesOnDynamicIsland" => true
```

---

### 問題 9: 階段切換時 Dynamic Island 消失

**現象**:
- 第一次 Focus 時 Dynamic Island 正常顯示
- 完成後切換到 Short Break 時 Dynamic Island 消失
- 之後所有階段都不再顯示

**診斷**:
在 `TimerEngine.swift` 的 `handleCompletion()` 方法中：

```swift
// 第 418 行：結束 Live Activity
if #available(iOS 16.1, *) {
    endLiveActivity()  // ❌ 這會讓 Dynamic Island 消失
}

// 第 448 行：1 秒後自動開始下一階段
try self.start()
```

雖然 `start()` 會調用 `startLiveActivity()`，但中間有延遲，導致 Dynamic Island 閃爍或消失。

**解決方案 (第一部分)**:
在 `handleCompletion()` 中改為更新而不是結束：

```swift
// Update Live Activity to show completion (don't end it - will continue to next session)
if #available(iOS 16.1, *) {
    updateLiveActivity()  // ✅ 更新顯示為 "Completed"
}
```

**解決方案 (第二部分)**:
在 `startLiveActivity()` 中添加智能判斷：

```swift
@available(iOS 16.1, *)
private func startLiveActivity() {
    // ... 權限檢查 ...

    let currentSessionCount = sessionManager.currentProgress.completedCount

    // 如果已有 Live Activity
    if let activity = currentActivity {
        // 檢查 attributes 是否改變
        if activity.attributes.sessionCount != currentSessionCount {
            // SessionCount 改變了（Focus → Break），需要重新創建
            print("🔄 [Live Activity] Session count changed, restarting Activity")
            endLiveActivity()
            // 繼續創建新的 Activity
        } else {
            // Attributes 未改變（Break → Focus），只需更新 content
            print("🔄 [Live Activity] Updating existing Live Activity")
            Task {
                await activity.update(.init(state: contentState, staleDate: nil))
            }
            return  // ✅ 保持 Dynamic Island 不消失
        }
    }

    // 創建新 Live Activity...
}
```

**修改文件**:
- `TomatoClock/Core/Services/TimerEngine.swift` (line 418)
- `TomatoClock/Core/Services/TimerEngine.swift` (lines 582-653)

**行為說明**:
- **Short Break → Focus**: 無縫切換，Dynamic Island 不消失（只更新內容）
- **Focus → Short/Long Break**: 短暫閃爍（因為 sessionCount 改變，必須重建）

---

### 問題 10: Live Activity 重建時的競態條件

**現象**:
實施問題 9 的修正後，Focus → Break 切換時 Dynamic Island 仍然消失，需要重新進入 app 按暫停再開始才會顯示。

**診斷**:
在 `TimerEngine.swift` 的 `startLiveActivity()` 方法中（lines 607-627）：

```swift
if activity.attributes.sessionCount != currentSessionCount {
    print("🔄 [Live Activity] Session count changed, restarting Activity")
    endLiveActivity()  // ❌ 這是異步的，但函數立即返回！
    // Continue to create new activity below - Line 614
}

// Create new Live Activity
// Line 629 開始創建新 Activity - 但舊的可能還沒結束！
```

`endLiveActivity()` 方法（lines 682-695）：

```swift
@available(iOS 16.1, *)
private func endLiveActivity() {
    guard let activity = currentActivity else { return }

    print("🔵 [Live Activity] Ending Live Activity...")

    Task {  // ❌ 異步執行！
        await activity.end(nil, dismissalPolicy: .immediate)
        currentActivity = nil  // 在函數返回後才執行
    }
}
```

**競態條件流程**:
1. Focus 完成 → sessionCount 增加
2. 調用 `startLiveActivity()` 開始 Break
3. 檢測到 sessionCount 改變（Focus → Break）
4. 調用 `endLiveActivity()` - 啟動異步 Task 但**立即返回**
5. 代碼**立即繼續**到 line 629 創建新 Activity
6. 與此同時，第 4 步的異步 Task 最終完成，設置 `currentActivity = nil`
7. 如果第 6 步在第 5 步之後發生，新的 Activity 引用就會丟失
8. Dynamic Island 消失，因為 `currentActivity` 被設為 `nil`

**解決方案**:
重構代碼以正確處理異步操作順序：

1. **添加異步版本的 endLiveActivity**：
```swift
@available(iOS 16.1, *)
private func endLiveActivityAsync() async {
    guard let activity = currentActivity else { return }

    print("🔵 [Live Activity] Ending Live Activity (async)...")

    await activity.end(nil, dismissalPolicy: .immediate)  // 等待完成
    currentActivity = nil
    print("✅ [Live Activity] Successfully ended")
}
```

2. **添加異步的創建 Activity 方法**：
```swift
@available(iOS 16.1, *)
private func createNewLiveActivity(
    contentState: TimerActivityAttributes.ContentState,
    sessionCount: Int
) async {
    print("🔵 [Live Activity] Creating new Live Activity...")
    print("   - Mode: \(contentState.mode.displayName)")
    print("   - Remaining: \(contentState.displayTime)")
    print("   - Session: #\(sessionCount + 1)")

    let attributes = TimerActivityAttributes(sessionCount: sessionCount)

    do {
        let activity = try Activity<TimerActivityAttributes>.request(
            attributes: attributes,
            content: .init(state: contentState, staleDate: nil),
            pushType: nil
        )
        currentActivity = activity
        print("✅ [Live Activity] Successfully started!")
        print("   - Activity ID: \(activity.id)")
    } catch {
        print("❌ [Live Activity] Failed to start: \(error)")
    }
}
```

3. **在 startLiveActivity 中正確使用異步順序**：
```swift
if activity.attributes.sessionCount != currentSessionCount {
    print("🔄 [Live Activity] Session count changed, restarting Activity")

    // 在 Task 中按順序執行異步操作
    Task { [weak self] in
        guard let self else { return }

        // 等待舊 Activity 完全結束
        await self.endLiveActivityAsync()

        // 現在創建新 Activity
        await self.createNewLiveActivity(
            contentState: contentState,
            sessionCount: currentSessionCount
        )
    }
    return
}
```

**修改文件**:
- `TomatoClock/Core/Services/TimerEngine.swift` (lines 607-650: startLiveActivity)
- `TomatoClock/Core/Services/TimerEngine.swift` (lines 697-738: 新增兩個異步方法)

**關鍵改進**:
- ✅ `endLiveActivityAsync()` 是真正的異步函數，調用者可以 `await` 它
- ✅ `createNewLiveActivity()` 也是異步的，確保操作順序
- ✅ 在 Task 中按順序執行：先 await 結束，再 await 創建
- ✅ 使用 `[weak self]` 避免記憶體洩漏
- ✅ 保留原來的 `endLiveActivity()` 用於 pause 等不需要重建的場景

**行為說明**:
- **Focus → Break**: 先等待舊 Activity 完全結束，再創建新的，避免競態條件
- **Break → Focus**: 無縫更新（不需要重建）
- **Pause**: 立即結束 Activity（不需要等待）

---

## 最終配置清單

### Widget Extension Info.plist (IslandInfo.plist)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>TomatoClock Island</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>$(MARKETING_VERSION)</string>
    <key>CFBundleVersion</key>
    <string>$(CURRENT_PROJECT_VERSION)</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.widgetkit-extension</string>
    </dict>
    <key>NSSupportsLiveActivities</key>
    <true/>
    <key>NSSupportsLiveActivitiesFrequentUpdates</key>
    <true/>
    <key>NSSupportsLiveActivitiesOnDynamicIsland</key>
    <true/>
</dict>
</plist>
```

### 主 App Build Settings (在 project.pbxproj 中)

```
GENERATE_INFOPLIST_FILE = YES;
INFOPLIST_KEY_NSSupportsLiveActivities = YES;
INFOPLIST_KEY_NSSupportsLiveActivitiesOnDynamicIsland = YES;
```

### Widget Extension Build Settings

```
GENERATE_INFOPLIST_FILE = NO;
INFOPLIST_FILE = tomatoclockisland/IslandInfo.plist;
CODE_SIGN_ENTITLEMENTS = tomatoclockisland/tomatoclockisland.entitlements;
IPHONEOS_DEPLOYMENT_TARGET = 16.1;
PRODUCT_BUNDLE_IDENTIFIER = "tomato-clock.TomatoClock.tomatoclockisland";
```

### App Groups (兩個 entitlements 文件都要)

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.tomato-clock.TomatoClock</string>
</array>
```

---

## 測試驗證步驟

### 1. 驗證 Build 產物

```bash
# 檢查主 app Info.plist
plutil -p "Build/Products/Debug-iphoneos/TomatoClock.app/Info.plist" | grep -i "live"

# 應該看到：
"NSSupportsLiveActivities" => true
"NSSupportsLiveActivitiesOnDynamicIsland" => true

# 檢查 widget extension Info.plist
plutil -p "Build/Products/Debug-iphoneos/TomatoClock.app/PlugIns/tomatoclockislandExtension.appex/Info.plist" | grep -i "live"

# 應該看到：
"NSSupportsLiveActivities" => true
"NSSupportsLiveActivitiesFrequentUpdates" => true
"NSSupportsLiveActivitiesOnDynamicIsland" => true

# 檢查 extension 是否嵌入
ls -la "Build/Products/Debug-iphoneos/TomatoClock.app/PlugIns/"

# 應該看到：
tomatoclockislandExtension.appex
```

### 2. 驗證日誌輸出

開始計時器時應該看到：
```
🔵 [Live Activity] Starting new Live Activity...
   - Mode: Focus
   - Remaining: 24:59
   - Session: #1
✅ [Live Activity] Successfully started!
   - Activity ID: [UUID]
💡 [Live Activity] Put app in background to see Dynamic Island
```

階段切換時應該看到（Break → Focus）：
```
🔄 [Live Activity] Updating existing Live Activity
   - Mode: Focus
   - Remaining: 24:59
✅ [Live Activity] Updated successfully!
```

或（Focus → Break）：
```
🔄 [Live Activity] Session count changed (0 → 1), restarting Activity
🔵 [Live Activity] Starting new Live Activity...
```

### 3. 功能測試

- ✅ 開始 Focus 時 Dynamic Island 顯示倒數計時
- ✅ 切換到背景，Dynamic Island 保持顯示
- ✅ Focus → Short Break 時 Dynamic Island 短暫閃爍後繼續顯示
- ✅ Short Break → Focus 時 Dynamic Island 無縫切換
- ✅ Pause 時 Dynamic Island 顯示 "PAUSED"
- ✅ Resume 時 Dynamic Island 繼續倒數
- ✅ 鎖定螢幕也顯示 Live Activity 卡片

---

## 關鍵學習

### 1. ActivityKit Attributes 的限制

ActivityKit 的 `ActivityAttributes` 在 Activity 創建後**不能更改**。如果需要改變 attributes（如 sessionCount），必須：
1. 結束舊的 Activity (`endLiveActivity()`)
2. 創建新的 Activity (`Activity.request()`)

這會導致 Dynamic Island 短暫消失。

**解決方案**：將頻繁變化的數據放在 `ContentState` 中，只將靜態或很少變化的數據放在 `ActivityAttributes` 中。

### 2. Live Activities 的三個必要鍵

| 鍵 | 位置 | 作用 |
|---|---|---|
| `NSSupportsLiveActivities` | 主 app + Widget Extension | 啟用 Live Activities 功能 |
| `NSSupportsLiveActivitiesFrequentUpdates` | Widget Extension | 允許高頻更新（倒數計時） |
| `NSSupportsLiveActivitiesOnDynamicIsland` | 主 app + Widget Extension | 啟用 Dynamic Island 顯示 |

**缺少任何一個都會導致功能不完整或完全無法工作。**

### 3. WidgetKit Extension 的現代配置

**舊版（已廢棄）**：
```xml
<key>NSExtensionPrincipalClass</key>
<string>MyWidgetBundle</string>
```

**新版（Swift 6 / iOS 16+）**：
```swift
@main
struct TomatoClockIslandBundle: WidgetBundle {
    var body: some Widget {
        TimerLiveActivityWidget()
    }
}
```

不需要 `NSExtensionPrincipalClass`，只需要 `NSExtensionPointIdentifier`。

### 4. 自動生成 vs 自定義 Info.plist

| 配置 | 使用方式 |
|---|---|
| `GENERATE_INFOPLIST_FILE = YES` | 使用 `INFOPLIST_KEY_*` 在 Build Settings 中設定 |
| `GENERATE_INFOPLIST_FILE = NO` | 使用自定義 Info.plist 文件 |

**不能混用**：如果設置為 YES，手動編輯的 Info.plist 會被忽略。

### 5. Dynamic Island UI 更新邏輯

```swift
// ❌ 錯誤：完成時立即結束
handleCompletion() {
    endLiveActivity()  // Dynamic Island 消失
    // 1 秒後...
    start()  // 重新創建，但中間有空檔
}

// ✅ 正確：完成時更新
handleCompletion() {
    updateLiveActivity()  // 顯示 "Completed"
    // 1 秒後...
    start() {
        if (canUpdate) {
            update()  // 無縫切換
        } else {
            endAndRestart()  // 短暫閃爍
        }
    }
}
```

---

## 參考資源

- [ActivityKit Documentation](https://developer.apple.com/documentation/activitykit)
- [Live Activities Tutorial](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)
- [Dynamic Island Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/live-activities)
- [Info.plist Keys](https://developer.apple.com/documentation/bundleresources/information_property_list)

---

## 總結

Dynamic Island 的實作涉及多個層面的正確配置：

1. **專案結構**：必須有獨立的 Widget Extension target
2. **Build Settings**：正確配置 Info.plist 路徑和生成選項
3. **Info.plist 鍵值**：主 app 和 widget extension 都需要 Live Activities 支持鍵
4. **代碼結構**：dynamicIsland 閉包必須直接返回 DynamicIsland
5. **生命週期管理**：智能更新 vs 重建，避免不必要的閃爍

所有這些配置都必須正確，才能讓 Dynamic Island 功能正常工作。
