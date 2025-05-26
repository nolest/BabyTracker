# 寶寶生活記錄專業版（Baby Tracker）- Xcode 測試步驟指南

本文檔提供在 Xcode 實體環境中測試「寶寶生活記錄專業版」應用的完整步驟。

## 前置需求

- Mac 電腦 (macOS Monterey 12.0 或更高版本)
- Xcode 13.0 或更高版本
- iOS 開發者帳戶 (免費帳戶即可用於測試)
- 實體 iOS 設備 (可選，但建議用於完整測試)
- CocoaPods (用於管理依賴)

## 步驟 1: 安裝必要工具

1. **安裝 Xcode**
   - 從 Mac App Store 下載並安裝 Xcode
   - 啟動 Xcode 並接受許可協議
   - 等待安裝必要的組件

2. **安裝 CocoaPods**
   - 打開終端機
   - 執行命令: `sudo gem install cocoapods`
   - 輸入管理員密碼
   - 確認安裝成功: `pod --version`

## 步驟 2: 導入專案

1. **解壓專案文件**
   - 解壓 `BabyTrackerApp_Complete.zip` 到您選擇的位置
   - 打開終端機，導航到解壓後的目錄: `cd 路徑/到/BabyTrackerApp`

2. **創建 Xcode 專案**
   - 啟動 Xcode
   - 選擇 "Create a new Xcode project"
   - 選擇 "App" 模板，點擊 "Next"
   - 填寫產品名稱: "寶寶生活記錄專業版"
   - 填寫 Organization Identifier (例如: "com.yourcompany")
   - 確保選擇 Swift 語言和 UIKit 界面
   - 選擇保存位置，點擊 "Create"

3. **導入源代碼文件**
   - 在 Xcode 專案導航器中，右鍵點擊專案根目錄
   - 選擇 "Add Files to [專案名稱]..."
   - 導航到解壓後的源代碼文件夾，選擇所有 .swift 文件
   - 確保勾選 "Copy items if needed" 和 "Create groups"
   - 點擊 "Add"

4. **導入資源文件**
   - 重複上述步驟，導入 Resources 文件夾中的資源

5. **配置專案設定**
   - 點擊專案導航器中的專案名稱
   - 在 "Info" 標籤頁中，根據 Config/project.xcconfig 文件更新設定
   - 在 "Signing & Capabilities" 標籤頁中，選擇您的開發團隊
   - 添加必要的功能: iCloud, Push Notifications, Background Modes

## 步驟 3: 安裝依賴

1. **創建 Podfile**
   - 在專案根目錄創建名為 "Podfile" 的文件
   - 添加以下內容:
   ```ruby
   platform :ios, '14.0'
   
   target '寶寶生活記錄專業版' do
     use_frameworks!
     
     # 核心依賴
     pod 'Combine-CombineExt'
     pod 'SwiftUI-Introspect'
     
     # 數據庫
     pod 'RealmSwift'
     
     # 網絡
     pod 'Alamofire'
     
     # UI 組件
     pod 'Charts'
     pod 'SnapKit'
     
     # 工具
     pod 'KeychainAccess'
     pod 'CryptoSwift'
     
     # 測試依賴
     target '寶寶生活記錄專業版Tests' do
       inherit! :search_paths
       pod 'Quick'
       pod 'Nimble'
     end
   end
   ```

2. **安裝依賴**
   - 在終端機中，導航到專案根目錄
   - 執行命令: `pod install`
   - 等待依賴安裝完成
   - 關閉 Xcode 專案，打開新生成的 `.xcworkspace` 文件

## 步驟 4: 配置模擬器測試

1. **選擇模擬器**
   - 在 Xcode 頂部工具欄，點擊設備選擇器
   - 選擇 iPhone 13 (或其他您想測試的設備)

2. **構建並運行**
   - 點擊 Xcode 頂部的運行按鈕 (▶️)
   - 等待應用構建並在模擬器中啟動
   - 如果出現構建錯誤，請檢查錯誤信息並修復

## 步驟 5: 實機測試 (推薦)

1. **連接 iOS 設備**
   - 使用 USB 線將 iPhone 或 iPad 連接到 Mac
   - 確保設備已解鎖並信任您的電腦

2. **配置設備開發**
   - 在 Xcode 中，選擇您的設備作為運行目標
   - 在 "Signing & Capabilities" 中，確保選擇了正確的開發團隊
   - 如果出現簽名錯誤，請嘗試使用自動簽名選項

3. **在設備上運行**
   - 點擊運行按鈕 (▶️)
   - 首次在設備上運行時，可能需要在設備上信任開發者證書:
     - 在 iOS 設備上，前往 設定 > 一般 > 裝置管理
     - 找到您的開發者證書並點擊"信任"

## 步驟 6: 功能測試

請按照以下順序測試主要功能:

1. **基本功能**
   - 創建寶寶檔案
   - 記錄睡眠時間
   - 記錄餵食
   - 記錄換尿布
   - 查看儀表板數據

2. **分析功能**
   - 查看睡眠分析
   - 檢查作息規律分析
   - 測試預測功能

3. **智能建議**
   - 查看建議列表
   - 點擊建議查看詳情
   - 測試建議反饋功能

4. **同步功能** (需要 iCloud 帳戶)
   - 啟用 iCloud 同步
   - 測試數據同步功能
   - 測試家庭共享功能

5. **AI 功能**
   - 測試本地 AI 分析
   - 測試雲端 AI 分析 (需要網絡連接)
   - 檢查分析結果的準確性

## 步驟 7: 測試驗證

測試過程中，請確認以下關鍵點:

- **UI 響應**: 所有界面是否流暢，無卡頓
- **數據持久化**: 關閉並重新打開應用後，數據是否保留
- **錯誤處理**: 測試離線模式、錯誤輸入等邊緣情況
- **內存使用**: 長時間使用後應用是否穩定
- **電池消耗**: 監控應用的電池使用情況

## 常見問題排解

1. **構建錯誤**
   - 確保 Xcode 版本兼容 (13.0+)
   - 檢查是否正確安裝了所有依賴
   - 清理專案 (Product > Clean Build Folder)

2. **簽名問題**
   - 確保開發者帳戶已正確設置
   - 嘗試重置簽名設置並重新選擇團隊

3. **模擬器問題**
   - 重置模擬器 (Device > Erase All Content and Settings)
   - 嘗試不同的模擬器設備

4. **API 連接問題**
   - 確認網絡連接
   - 檢查 API 密鑰配置是否正確

5. **iCloud 同步問題**
   - 確保在模擬器/設備上登錄了 iCloud 帳戶
   - 檢查 iCloud 容器配置是否正確

## 結論

完成上述步驟後，您應該能夠在 Xcode 環境中成功測試「寶寶生活記錄專業版」應用的所有功能。如果遇到任何問題，請參考文檔或聯繫開發團隊獲取支持。
