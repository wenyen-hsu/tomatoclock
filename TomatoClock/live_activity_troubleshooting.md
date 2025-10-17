# Live Activity / 動態島故障排查指南
# Live Activity / Dynamic Island Troubleshooting Guide

> **問題**: 啟動計時器後，動態島沒有顯示倒數
> **創建日期**: 2025-10-16

---

## 🔍 診斷檢查清單

### 1. 設備兼容性檢查

**動態島支持的設備**：
- ✅ iPhone 14 Pro
- ✅ iPhone 14 Pro Max
- ✅ iPhone 15 Pro
- ✅ iPhone 15 Pro Max
- ✅ iPhone 16 Pro
- ✅ iPhone 16 Pro Max

**不支持動態島的設備**：
- ❌ iPhone 14 / 14 Plus（沒有動態島硬件）
- ❌ iPhone 15 / 15 Plus（沒有動態島硬件）
- ❌ 所有 iPhone 13 及更早機型

⚠️ **重要**：如果你的 iPhone 不支持動態島，Live Activity 仍然會顯示，但會出現在：
- 鎖屏畫面
- 通知中心（下拉查看）

**檢查方法**：
```
設定 > 一般 > 關於本機
查看「機型名稱」
```

---

### 2. iOS 版本檢查

**最低要求**: iOS 16.1 或更高版本

**檢查方法**：
```
設定 > 一般 > 軟件更新
```

如果低於 iOS 16.1，Live Activities 功能不可用。

---

### 3. Live Activities 系統權限檢查

#### 方法 A: 在 iPhone 設定中檢查

1. 打開「**設定**」
2. 滾動找到「**番茄鐘**」（TomatoClock）
3. 檢查是否有「**即時動態**」或「**Live Activities**」選項
4. 確保開關為「**開啟**」狀態

如果沒有看到此選項，可能是：
- App 第一次安裝，系統還未顯示此選項
- 需要重新安裝 app

#### 方法 B: 檢查動態島全局設定（iOS 17+）

1. 打開「**設定**」
2. 選擇「**動態島與待命顯示**」
3. 確保「**即時動態**」為開啟狀態

---

### 4. Widget Extension 安裝檢查

Widget Extension 必須隨主 app 一起安裝到設備。

**檢查方法**：

#### 在 Xcode 中檢查

1. 打開 Xcode
2. 選單：**Product > Scheme > Edit Scheme...** (⌘<)
3. 選擇左側的「**Run**」
4. 在右側「**Info**」標籤中，檢查「**Executable**」
5. 確保選擇的是「**TomatoClock.app**」

#### 檢查 Build Targets

在 Xcode 專案導航器中，確認有兩個 targets：
- ✅ TomatoClock（主 app）
- ✅ tomatoclockisland（widget extension）

兩者都應該被勾選以進行編譯。

---

### 5. 查看 Xcode 控制台日誌

Live Activity 的啟動會在控制台輸出日誌信息。

**如何查看**：

1. 在 Xcode 中運行 app 到實體設備
2. 打開控制台（View > Debug Area > Activate Console 或 ⌘⇧Y）
3. 啟動計時器
4. 查看控制台輸出

**正常日誌**（成功）：
```
✅ Live Activity started: <Activity ID>
```

**異常日誌**（失敗）：
```
❌ Failed to start Live Activity: <error message>
```

或

```
Live Activities are not enabled
```

---

## 🐛 常見問題及解決方案

### 問題 1: 控制台顯示 "Live Activities are not enabled"

**原因**: Live Activities 權限未啟用

**解決方案**：

1. **卸載 app**：長按圖標 > 移除 App > 刪除 App
2. **重新安裝**：在 Xcode 中重新運行到設備（⌘R）
3. **首次啟動時授予權限**：
   - 首次啟動計時器時，iOS 會彈出權限請求
   - 點擊「**允許**」

4. **如果沒有彈出權限請求**：
   - 進入 設定 > 番茄鐘
   - 手動開啟「即時動態」

---

### 問題 2: Widget Extension 未安裝

**症狀**: 主 app 正常運行，但 Live Activity 功能完全不工作

**解決方案**：

1. **清理 Build**：
   ```bash
   # 在終端執行
   cd /Users/wenhsu/Documents/wenyen/TomatoClockClean/TomatoClock
   xcodebuild clean -project TomatoClock.xcodeproj
   ```

2. **刪除 DerivedData**：
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/TomatoClock-*
   ```

3. **重新編譯所有 Targets**：
   - 在 Xcode 中：Product > Clean Build Folder（⌘⇧K）
   - 然後：Product > Build（⌘B）
   - 確認兩個 targets 都成功編譯

4. **重新安裝到設備**：
   - 刪除設備上的舊 app
   - 重新運行（⌘R）

---

### 問題 3: 動態島沒有顯示，但鎖屏有顯示

**原因**: 這是正常的！在某些情況下，動態島的顯示策略如下：

- **App 在前台**：動態島不顯示（因為你正在使用 app）
- **App 在後台**：動態島應該顯示
- **鎖屏**：總是顯示 Live Activity

**測試步驟**：

1. 啟動計時器
2. **立即按下 Home 鍵或向上滑動**（回到主畫面）
3. **等待 2-3 秒**讓動態島動畫顯示
4. 查看螢幕頂部的動態島區域

如果動態島仍然沒有顯示：
- 鎖定螢幕，檢查 Live Activity 是否在鎖屏顯示
- 如果鎖屏有顯示，說明 Live Activity 工作正常，只是動態島沒有優先顯示

---

### 問題 4: 錯誤信息 "Failed to start Live Activity"

**可能原因**：
1. ActivityAttributes 序列化失敗
2. 系統資源不足
3. 已有太多 Live Activities 運行

**解決方案**：

1. **重啟 iPhone**
2. **結束其他 app 的 Live Activities**：
   - 查看動態島和鎖屏
   - 關閉不需要的 Live Activities
3. **檢查 iPhone 儲存空間**：
   - 設定 > 一般 > iPhone 儲存空間
   - 確保有足夠空間

---

### 問題 5: Live Activity 顯示但不自動更新倒數

**症狀**: 動態島出現了，但時間不倒數，一直停留在初始時間

**可能原因**:
1. `timerEndDate` 沒有正確設置
2. Widget 沒有使用 `.timer` style

**檢查代碼**：

查看 `tomatoclockisland/TimerLiveActivityWidget.swift`，確認使用了：
```swift
Text(context.state.timerEndDate, style: .timer)
```

而不是：
```swift
Text(context.state.displayTime)  // ❌ 這樣不會自動更新
```

---

## 🔬 詳細調試步驟

### 步驟 1: 添加更詳細的日誌

如果以上都無法解決，我們可以添加更詳細的調試輸出。

### 步驟 2: 檢查 Activity Authorization

在 app 啟動時檢查授權狀態。

### 步驟 3: 手動觸發 Live Activity

創建一個測試按鈕來手動觸發 Live Activity，而不是依賴計時器啟動。

---

## 📋 完整測試流程

**按照以下順序進行完整測試**：

1. ✅ **確認設備型號**：iPhone 14 Pro 或更新的 Pro 機型
2. ✅ **確認 iOS 版本**：iOS 16.1+
3. ✅ **卸載並重新安裝 app**
4. ✅ **首次啟動時允許 Live Activities 權限**
5. ✅ **啟動計時器**
6. ✅ **立即將 app 切換到後台**（Home 鍵或向上滑動）
7. ✅ **等待 2-3 秒**
8. ✅ **查看動態島區域**

如果動態島沒有顯示：
1. ✅ **鎖定螢幕，檢查 Live Activity 是否在鎖屏顯示**
2. ✅ **查看 Xcode 控制台日誌**

---

## 💡 關鍵發現

### Live Activity 顯示優先級

iOS 系統對 Live Activity 的顯示有優先級策略：

1. **最高優先級**：音樂播放、通話、導航
2. **中等優先級**：計時器、健身追蹤
3. **低優先級**：其他 app 的 Live Activities

如果同時有多個 Live Activities，系統可能：
- 只在動態島顯示優先級最高的
- 其他的顯示在鎖屏

---

## 📝 報告問題時需要提供的信息

如果問題持續存在，請提供以下信息：

1. **設備型號**：設定 > 一般 > 關於本機 > 機型名稱
2. **iOS 版本**：設定 > 一般 > 關於本機 > 軟件版本
3. **Xcode 控制台日誌**：
   - 啟動計時器時的所有日誌輸出
   - 特別是包含 "Live Activity" 的行
4. **設定截圖**：
   - 設定 > 番茄鐘 > 即時動態
   - 設定 > 動態島與待命顯示
5. **鎖屏截圖**：
   - 啟動計時器後鎖定螢幕的截圖
   - 確認 Live Activity 是否在鎖屏顯示

---

## 🎯 快速診斷命令

在你的 iPhone 上執行這些檢查：

```
✅ 設備型號: iPhone [    ] Pro
✅ iOS 版本: [    ]
✅ Live Activities 系統開關: 開啟 / 關閉
✅ App 的即時動態權限: 開啟 / 關閉
✅ Xcode 控制台日誌: 看到 "✅ Live Activity started" / "❌ Failed" / 沒有日誌
✅ 鎖屏是否顯示: 有 / 沒有
✅ 動態島是否顯示: 有 / 沒有
```

---

**文檔版本**: 1.0
**最後更新**: 2025-10-16
**適用於**: iOS 16.1+, iPhone 14 Pro+
