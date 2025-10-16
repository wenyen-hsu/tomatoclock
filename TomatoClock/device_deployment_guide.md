# 實體設備部署指南
# Physical Device Deployment Guide

> **目標**: 在 iPhone 實體設備上運行番茄鐘 app
> **創建日期**: 2025-10-16

---

## 📱 當前配置狀態

### 專案配置
- ✅ **Code Signing Style**: Automatic（自動簽名）
- ✅ **Development Team**: QSJ2X775UA
- ✅ **Bundle Identifier**: tomato-clock.TomatoClock
- ✅ **Code Signing Allowed**: YES

**結論**: 專案配置正確，可以部署到實體設備。

---

## 🔧 在實體設備上運行的步驟

### 步驟 1: 連接 iPhone 到電腦

1. 使用 USB 線將 iPhone 連接到 Mac
2. 在 iPhone 上，如果出現「信任此電腦？」提示：
   - 點擊「**信任**」
   - 輸入 iPhone 的密碼
3. 等待 Xcode 識別設備（可能需要幾秒鐘）

### 步驟 2: 在 Xcode 中打開專案

```bash
# 在終端中執行
open TomatoClock.xcodeproj
```

或者：
- 雙擊 `TomatoClock.xcodeproj` 文件
- 從 Xcode 的 File > Open 選單打開

### 步驟 3: 選擇實體設備作為目標

在 Xcode 中：

1. **查看工具列頂部**，找到設備選擇器（Scheme 旁邊）

   當前可能顯示：
   ```
   TomatoClock > iPhone 15 Pro (Simulator)
   ```

2. **點擊設備選擇器**，會出現下拉選單

3. **在下拉選單中找到你的 iPhone**：
   ```
   ┌─────────────────────────────────┐
   │ iOS Device                      │
   │   ✓ Wen 的 iPhone (連接中)      │  ← 選擇這個
   │                                 │
   │ iOS Simulator                   │
   │   iPhone 15 Pro                 │
   │   iPhone 14 Pro                 │
   │   ...                           │
   └─────────────────────────────────┘
   ```

4. **選擇你的實體 iPhone**

### 步驟 4: 構建並運行

1. **確認目標設備正確**：
   - 工具列應該顯示：`TomatoClock > [你的 iPhone 名稱]`

2. **點擊運行按鈕** ▶️ 或按 **⌘R**

3. **第一次運行時的處理**：

   #### 如果出現「開發者未驗證」錯誤：

   在 iPhone 上：
   1. 進入「**設定**」
   2. 選擇「**一般**」
   3. 選擇「**VPN 與裝置管理**」或「**描述檔與裝置管理**」
   4. 找到你的 Apple ID 或開發者證書
   5. 點擊「**信任 [你的開發者帳號]**」
   6. 確認信任

   #### 如果出現簽名錯誤：

   在 Xcode 中：
   1. 選擇專案導航器中的 **TomatoClock** 專案
   2. 選擇 **TomatoClock** target
   3. 進入「**Signing & Capabilities**」標籤
   4. 確認「**Automatically manage signing**」已勾選
   5. 選擇你的「**Team**」（Apple ID）
   6. 如果沒有 Team，點擊「**Add Account...**」添加你的 Apple ID

4. **等待構建和安裝**：
   - Xcode 會自動構建 app
   - 將 app 安裝到你的 iPhone
   - 自動啟動 app

---

## ❓ 常見問題排解

### 問題 1: 找不到我的 iPhone

**症狀**: 設備選擇器中沒有顯示我的 iPhone

**解決方案**:

1. **檢查 USB 連接**：
   - 重新插拔 USB 線
   - 嘗試不同的 USB 埠
   - 確認使用的是數據線（非僅充電線）

2. **檢查 iPhone 是否已解鎖**：
   - 確保 iPhone 沒有鎖定
   - 在主畫面狀態下

3. **檢查信任設定**：
   - iPhone 上應該出現「信任此電腦？」提示
   - 選擇「信任」

4. **重啟服務**：
   ```bash
   # 在終端執行
   sudo pkill usbmuxd
   ```
   - 這會重啟 USB 連接服務
   - iPhone 會自動重新連接

5. **在 Xcode 中檢查**：
   - 選單：Window > Devices and Simulators
   - 切換到「Devices」標籤
   - 查看你的 iPhone 是否列出
   - 如果顯示黃色警告，點擊解決

### 問題 2: 「開發者模式未啟用」（iOS 16+）

**症狀**: iOS 16 或更新版本要求啟用開發者模式

**解決方案**:

在 iPhone 上：
1. 進入「**設定**」
2. 選擇「**隱私權與安全性**」
3. 滾動到底部，選擇「**開發者模式**」
4. 開啟「**開發者模式**」
5. 重新啟動 iPhone
6. 重啟後會要求確認，點擊「啟用」

### 問題 3: 「無法驗證 app」或「未受信任的開發者」

**症狀**: App 安裝後無法打開，顯示安全警告

**解決方案**:

在 iPhone 上：
1. 進入「**設定**」 > 「**一般**」
2. 選擇「**VPN 與裝置管理**」
3. 在「開發者 App」下找到你的證書
4. 點擊證書
5. 點擊「**信任 "[你的 Apple ID]"**」
6. 在彈出視窗中確認「**信任**」

### 問題 4: 簽名錯誤 "Code Sign error"

**症狀**: 構建時出現代碼簽名錯誤

**解決方案**:

#### 方案 A: 使用個人 Apple ID（免費）

1. 在 Xcode 中：
   - 選擇 **TomatoClock** target
   - 進入「**Signing & Capabilities**」
   - 勾選「**Automatically manage signing**」
   - 點擊「Team」下拉選單
   - 選擇「**Add an Account...**」

2. 登錄你的 Apple ID（可以是免費帳號）

3. 回到「Signing & Capabilities」：
   - 選擇你剛添加的 Apple ID 作為 Team
   - Xcode 會自動處理證書和配置

#### 方案 B: 修改 Bundle Identifier（如果需要）

如果上述方法不行，可能是 Bundle Identifier 衝突：

1. 在「Signing & Capabilities」中
2. 修改「**Bundle Identifier**」：
   ```
   原來：tomato-clock.TomatoClock
   改成：com.[你的名字].TomatoClock
   例如：com.wenhsu.TomatoClock
   ```

### 問題 5: "No applicable devices connected"

**症狀**: 點擊運行時提示沒有可用設備

**解決方案**:

1. **確認設備已連接且已信任**
2. **確認設備已解鎖**
3. **在 Xcode 中重新選擇設備**
4. **重啟 Xcode**：
   - 退出 Xcode（⌘Q）
   - 重新打開專案

### 問題 6: Widget Extension 無法安裝

**症狀**: 主 app 可以安裝，但 widget 或 Live Activity 不工作

**解決方案**:

這是正常的！第一次安裝時需要：

1. **確保主 app 已成功安裝並運行**
2. **Widget Extension 會自動隨主 app 安裝**
3. **Live Activity 需要在 app 內觸發**（啟動計時器時）

如果 Live Activity 仍然不顯示：

1. **檢查 iPhone 設定**：
   - 設定 > 動態島與待命顯示
   - 確認「即時動態」已啟用

2. **檢查 app 設定**：
   - 設定 > 番茄鐘 > 通知
   - 確認「即時動態」已允許

---

## 🎯 快速檢查清單

在嘗試在實體設備上運行前，確認以下項目：

- [ ] iPhone 已通過 USB 連接到 Mac
- [ ] iPhone 已解鎖（在主畫面）
- [ ] iPhone 上已點擊「信任此電腦」
- [ ] Xcode 中可以看到設備（Window > Devices and Simulators）
- [ ] iOS 16+ 已啟用開發者模式
- [ ] 在 Xcode 的設備選擇器中選擇了實體設備（而非模擬器）
- [ ] 「Signing & Capabilities」中已設定 Team
- [ ] 「Automatically manage signing」已勾選

---

## 📸 視覺指南

### Xcode 設備選擇器位置

```
┌─────────────────────────────────────────────────────────────┐
│ File  Edit  View  Navigate  Editor  Product  Debug  ...    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ▶️ [TomatoClock ▼] > [iPhone 15 Pro ▼]    ← 點擊這裡      │
│     ^^^^^^^^^^^^^      ^^^^^^^^^^^^^^^^                     │
│     Scheme             Device Selector                      │
│                                                             │
```

### 設備選擇器展開後

```
┌──────────────────────────────────┐
│ iOS Device                       │
│   Wen 的 iPhone 14 Pro  ← 實體   │  ← 選擇這個！
│                                  │
├──────────────────────────────────┤
│ iOS Simulator                    │
│   iPhone 15 Pro                  │
│   iPhone 14 Pro                  │
│   iPhone SE (3rd generation)     │
└──────────────────────────────────┘
```

---

## 🚀 部署後驗證

成功在實體設備上運行後，驗證以下功能：

### 基本功能
- [ ] App 成功啟動
- [ ] UI 正常顯示
- [ ] 可以啟動計時器
- [ ] 計時器倒數正常

### Live Activity / 動態島功能
- [ ] 啟動計時器時，動態島出現
- [ ] 緊湊模式顯示倒數計時
- [ ] 長按動態島可以展開
- [ ] 展開模式顯示詳細信息
- [ ] 鎖屏時顯示 Live Activity
- [ ] 倒數計時自動更新

### 性能
- [ ] App 反應流暢
- [ ] 無明顯卡頓
- [ ] 計時準確
- [ ] 電池消耗正常

---

## 💡 專業建議

### 開發過程中
1. **主要使用模擬器開發**
   - 更快的構建和部署
   - 不消耗設備電量
   - 容易測試不同設備尺寸

2. **定期在實體設備測試**
   - 每完成一個功能後
   - 準備發布前
   - 測試動態島等設備特定功能

3. **使用 TestFlight 進行 Beta 測試**
   - 對於更廣泛的測試
   - 可以分發給其他測試人員

### 動態島測試
⚠️ **重要**: 動態島功能**只能在實體設備上完整測試**

支持的設備：
- iPhone 14 Pro / 14 Pro Max
- iPhone 15 Pro / 15 Pro Max
- iPhone 16 Pro / 16 Pro Max

模擬器限制：
- 模擬器無法完全模擬動態島
- Live Activity 在模擬器上的行為可能不同
- 必須使用實體設備進行最終驗證

---

## 🔄 如果一切都不行

### 最後的解決方案

1. **清理專案**：
   ```bash
   # 在終端中執行
   cd /Users/wenhsu/Documents/wenyen/TomatoClockClean/TomatoClock
   xcodebuild clean -project TomatoClock.xcodeproj
   rm -rf ~/Library/Developer/Xcode/DerivedData/TomatoClock-*
   ```

2. **重新打開專案**：
   - 退出 Xcode
   - 斷開 iPhone 連接
   - 重新打開 Xcode 和專案
   - 重新連接 iPhone

3. **重啟設備**：
   - 重啟 iPhone
   - 重啟 Mac（如果需要）

4. **檢查 macOS 和 Xcode 版本**：
   - 確保使用最新版本的 Xcode
   - 確保 macOS 版本與 Xcode 相容
   - 確保 iOS 版本與 Xcode 相容

---

## 📞 獲取幫助

如果問題仍未解決：

1. **檢查 Xcode 日誌**：
   - View > Navigators > Report Navigator
   - 查看詳細的構建和運行日誌

2. **檢查設備日誌**：
   - Window > Devices and Simulators
   - 選擇你的設備
   - 點擊「Open Console」查看設備日誌

3. **Apple 開發者論壇**：
   - https://developer.apple.com/forums/

4. **Stack Overflow**：
   - 搜索具體的錯誤信息

---

**文檔版本**: 1.0
**最後更新**: 2025-10-16
**適用於**: Xcode 15+, iOS 16+
