# 動態島調試指南
# Dynamic Island Debug Guide

> **版本**: v1.0.2 with Enhanced Logging
> **日期**: 2025-10-16

---

## 🆕 最新更新

已添加詳細的調試日誌輸出到 `TimerEngine.swift`。當你啟動計時器時，會在 Xcode 控制台看到以下日誌：

### 成功啟動的日誌示例：
```
🔵 [Live Activity] Attempting to start Live Activity...
🔵 [Live Activity] Authorization status: areActivitiesEnabled = true
🔵 [Live Activity] ContentState prepared:
   - Mode: 專注時間
   - Remaining: 25:00
   - End Date: 2025-10-16 23:25:00 +0000
✅ [Live Activity] Successfully started!
   - Activity ID: ABC123...
   - Activity State: active
💡 [Live Activity] Put app in background to see Dynamic Island
```

### 權限未啟用的日誌示例：
```
🔵 [Live Activity] Attempting to start Live Activity...
🔵 [Live Activity] Authorization status: areActivitiesEnabled = false
❌ [Live Activity] Live Activities are not enabled in system settings
💡 [Live Activity] Please enable in: Settings > TomatoClock > Live Activities
```

### 其他錯誤的日誌示例：
```
🔵 [Live Activity] Attempting to start Live Activity...
🔵 [Live Activity] Authorization status: areActivitiesEnabled = true
🔵 [Live Activity] ContentState prepared:
   - Mode: 專注時間
   - Remaining: 25:00
   - End Date: 2025-10-16 23:25:00 +0000
❌ [Live Activity] Failed to start: <error message>
   - Error details: <detailed description>
```

---

## 📋 測試步驟（按順序執行）

### 第 1 步：確認設備型號

**你的 iPhone 是否支持動態島？**

| 支持動態島 ✅ | 不支持動態島 ❌ |
|---|---|
| iPhone 14 Pro | iPhone 14 |
| iPhone 14 Pro Max | iPhone 14 Plus |
| iPhone 15 Pro | iPhone 15 |
| iPhone 15 Pro Max | iPhone 15 Plus |
| iPhone 16 Pro | 所有 iPhone 13 及更早 |
| iPhone 16 Pro Max | |

**檢查方法**：
```
設定 > 一般 > 關於本機 > 機型名稱
```

⚠️ **重要**：如果你的 iPhone 不支持動態島，Live Activity 仍然可以工作，但只會顯示在：
- **鎖屏畫面**
- **通知中心**（下拉查看）

---

### 第 2 步：重新安裝 App

**為什麼要重新安裝？**
- 確保 Widget Extension 正確安裝
- 重置 Live Activities 權限請求

**操作步驟**：

1. **刪除舊版本**：
   - 在 iPhone 上長按 TomatoClock 圖標
   - 選擇「移除 App」> 「刪除 App」

2. **在 Xcode 中重新編譯並運行**：
   - 確保選擇了你的實體設備（不是模擬器）
   - 點擊運行按鈕 ▶️ 或按 ⌘R
   - 等待編譯和安裝完成

---

### 第 3 步：查看 Xcode 控制台

**打開控制台**：
- Xcode 選單：View > Debug Area > Activate Console
- 或按快捷鍵：⌘⇧Y

**你應該看到的內容**：
在 app 啟動後，控制台會顯示各種日誌。關鍵是要看到「Live Activity」相關的日誌。

---

### 第 4 步：啟動計時器並觀察日誌

1. **在 iPhone 上啟動番茄鐘計時器**
   - 點擊「開始」按鈕

2. **立即查看 Xcode 控制台**
   - 你應該看到以 🔵 開頭的日誌

3. **檢查日誌內容**：

   #### ✅ 情況 A：看到「Successfully started」
   ```
   ✅ [Live Activity] Successfully started!
   ```

   **這意味著 Live Activity 成功啟動！**

   **下一步**：
   - 按 Home 鍵（或向上滑動）將 app 切換到後台
   - 等待 2-3 秒
   - 查看螢幕頂部動態島區域
   - 如果沒有看到動態島，鎖定螢幕查看 Live Activity

   #### ❌ 情況 B：看到「not enabled」
   ```
   ❌ [Live Activity] Live Activities are not enabled
   ```

   **問題**：權限未啟用

   **解決方案**：
   1. 進入 iPhone **設定**
   2. 滾動找到 **番茄鐘**（TomatoClock）
   3. 確認有「**即時動態**」選項
   4. 開啟此選項
   5. 返回 app，重新啟動計時器

   **如果找不到「即時動態」選項**：
   - 可能需要卸載並重新安裝 app
   - 或者嘗試在 iOS 設定 > 動態島與待命顯示 中檢查

   #### ❌ 情況 C：看到其他錯誤
   ```
   ❌ [Live Activity] Failed to start: <error>
   ```

   **問題**：其他系統錯誤

   **解決方案**：
   1. 記下完整的錯誤信息
   2. 重啟 iPhone
   3. 重新安裝 app
   4. 如果仍然失敗，請將完整錯誤信息提供給我

   #### ⚠️ 情況 D：完全沒有看到日誌

   **問題**：計時器沒有觸發 Live Activity，或控制台過濾設置有問題

   **解決方案**：
   1. 檢查控制台右下角的過濾器
   2. 在搜索框中輸入「Live Activity」
   3. 確保沒有過濾掉相關日誌
   4. 或者查看所有日誌（清除搜索框）

---

### 第 5 步：測試動態島顯示

**如果日誌顯示 Live Activity 成功啟動**：

1. **啟動計時器**
2. **立即按 Home 鍵**（或向上滑動）回到主畫面
3. **等待 2-3 秒**
4. **查看螢幕頂部的動態島區域**

**預期行為**：

- **動態島應該顯示**：
  - 左側：番茄圖標 🍅
  - 右側：倒數時間（例如：24:59）

- **長按動態島**：
  - 應該展開顯示完整信息
  - 包括進度條、模式名稱等

**如果動態島沒有顯示**：

1. **鎖定螢幕**（按電源鍵）
2. **檢查鎖屏是否有 Live Activity 卡片**
3. 如果鎖屏有顯示，說明 Live Activity 正常工作
4. 動態島可能被其他 Live Activity 佔用（iOS 只顯示優先級最高的）

---

### 第 6 步：測試自動倒數

**如果動態島或鎖屏顯示了 Live Activity**：

1. **觀察時間是否自動倒數**
   - 時間應該每秒自動減少
   - 例如：25:00 → 24:59 → 24:58...

2. **控制台日誌**：
   - 每 10 秒會看到一次更新日誌：
   ```
   🔄 [Live Activity] Updating... Remaining: 24:50
   ```

**如果時間不倒數**：
- 這不應該發生（代碼使用了 `.timer` style）
- 請提供截圖和控制台日誌

---

## 🧪 完整測試檢查清單

複製此檢查清單並填寫結果：

```
□ 設備型號: iPhone _____ Pro
□ iOS 版本: _____
□ App 已刪除並重新安裝
□ Xcode 控制台已打開

啟動計時器後：
□ 看到 "🔵 [Live Activity] Attempting to start"
□ 看到 "areActivitiesEnabled = true/false"
   - 結果: _____
□ 看到 "✅ Successfully started" 或 "❌ Failed"
   - 結果: _____

如果成功啟動：
□ 切換到後台後等待 2-3 秒
□ 動態島有顯示: 是 / 否
□ 鎖屏有顯示 Live Activity: 是 / 否
□ 時間自動倒數: 是 / 否
□ 每 10 秒看到更新日誌: 是 / 否

如果失敗：
□ 錯誤信息: _____________________
```

---

## 🔧 常見問題快速修復

### 問題：「areActivitiesEnabled = false」

**解決方案 A**：啟用權限
```
設定 > 番茄鐘 > 即時動態 > 開啟
```

**解決方案 B**：重新安裝
1. 刪除 app
2. 重新從 Xcode 安裝
3. 首次啟動計時器時允許權限

### 問題：動態島沒顯示，但鎖屏有

**原因**：這是正常的！
- iOS 動態島有優先級系統
- 如果同時有多個 Live Activities，只顯示最高優先級
- 其他的會在鎖屏顯示

**驗證方法**：
- 關閉其他正在運行的 Live Activities（音樂、計時器等）
- 重新啟動番茄鐘計時器

### 問題：完全沒有日誌輸出

**解決方案**：
1. 確認在 Xcode 中運行（不是 TestFlight）
2. 確認控制台已打開（⌘⇧Y）
3. 清除控制台搜索過濾器
4. 重新啟動 app

---

## 📞 報告問題時請提供

如果問題仍未解決，請提供以下信息：

1. **設備信息**：
   - 機型：iPhone _____
   - iOS 版本：_____

2. **完整的控制台日誌**（從啟動計時器開始）：
   ```
   [複製所有包含 "Live Activity" 的日誌行]
   ```

3. **截圖**：
   - Xcode 控制台截圖
   - iPhone 鎖屏截圖（啟動計時器後）
   - iPhone 設定 > 番茄鐘 截圖

4. **測試檢查清單**（填寫完整）

---

## 💡 專業提示

1. **開發過程中的測試**：
   - 主要在模擬器上開發 UI
   - 定期在實體設備上測試 Live Activity
   - 動態島功能只能在實體設備上完整測試

2. **調試技巧**：
   - 使用日誌中的表情符號快速識別類型：
     - 🔵 = 信息
     - ✅ = 成功
     - ❌ = 錯誤
     - 💡 = 提示
     - 🔄 = 更新中

3. **性能考慮**：
   - Live Activity 更新已優化為每秒自動（使用 .timer style）
   - 不會額外消耗電池
   - 控制台日誌限制為每 10 秒一次，避免過多輸出

---

**文檔版本**: 1.0
**最後更新**: 2025-10-16 23:10
**適用於**: TomatoClock v1.0.2+, iOS 16.1+
