# 寶寶生活記錄專業版（Baby Tracker）- 第一階段：專案結構

## 專案目錄結構

```
BabyTracker/
├── Application/                  # 應用程式入口點
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   └── BabyTrackerApp.swift      # SwiftUI App 入口點
│
├── Core/                         # 核心功能模組
│   ├── Constants/                # 常數定義
│   ├── Extensions/               # Swift 擴展
│   ├── Protocols/                # 協議定義
│   └── Utilities/                # 工具類
│
├── Data/                         # 數據層
│   ├── CoreData/                 # Core Data 相關
│   │   ├── BabyTracker.xcdatamodeld  # 數據模型
│   │   ├── CoreDataManager.swift     # Core Data 管理器
│   │   └── Entities/                 # 實體擴展
│   │
│   ├── Repositories/             # 數據存取層
│   │   ├── BabyRepository.swift
│   │   ├── SleepRepository.swift
│   │   └── ActivityRepository.swift
│   │
│   └── Services/                 # 服務層
│       ├── DataSyncService.swift     # 數據同步服務（預留）
│       └── AnalyticsService.swift    # 分析服務（預留）
│
├── Domain/                       # 領域層
│   ├── Models/                   # 業務模型
│   │   ├── Baby.swift
│   │   ├── SleepRecord.swift
│   │   └── Activity.swift
│   │
│   └── UseCases/                 # 用例
│       ├── BabyUseCases.swift
│       ├── SleepUseCases.swift
│       └── ActivityUseCases.swift
│
├── Presentation/                 # 表現層（MVVM）
│   ├── ViewModels/               # 視圖模型
│   │   ├── BabyViewModel.swift
│   │   ├── SleepViewModel.swift
│   │   └── ActivityViewModel.swift
│   │
│   └── Views/                    # 視圖
│       ├── Common/               # 共用元件
│       ├── Baby/                 # 寶寶相關視圖
│       ├── Sleep/                # 睡眠相關視圖
│       └── Activity/             # 活動相關視圖
│
└── Resources/                    # 資源文件
    ├── Assets.xcassets           # 圖片資源
    ├── Colors.xcassets           # 顏色資源
    ├── Localizable.strings       # 本地化字串
    └── Info.plist                # 應用配置
```

## 架構說明

本專案採用 MVVM (Model-View-ViewModel) 架構模式，並結合 Clean Architecture 的思想，將應用分為以下幾層：

### 1. 表現層 (Presentation Layer)

負責 UI 相關的邏輯，包含 Views 和 ViewModels：
- **Views**：使用 SwiftUI 和 UIKit 混合開發的用戶界面
- **ViewModels**：處理視圖邏輯，提供視圖所需的數據和行為

### 2. 領域層 (Domain Layer)

包含業務邏輯和規則，獨立於任何框架：
- **Models**：業務實體模型
- **UseCases**：應用的業務邏輯

### 3. 數據層 (Data Layer)

負責數據的獲取和存儲：
- **Repositories**：提供數據訪問的抽象接口
- **CoreData**：本地數據存儲實現
- **Services**：提供外部服務的接口

## 依賴管理

本專案使用 Swift Package Manager (SPM) 管理第三方依賴。主要依賴包括：

- **Charts**：用於數據可視化
- **Combine**：用於響應式編程

## 設計模式

專案中使用的主要設計模式：

1. **MVVM**：分離視圖和業務邏輯
2. **Repository**：抽象數據訪問層
3. **Dependency Injection**：降低模組間耦合
4. **Observer**：使用 Combine 實現響應式更新
5. **Factory**：創建複雜對象

## 代碼規範

- 遵循 Swift API Design Guidelines
- 使用 SwiftLint 確保代碼質量
- 採用 PascalCase 命名類型，camelCase 命名變量和函數
- 使用明確的類型註解，避免過度使用類型推斷
- 每個文件只包含一個主要類型
- 使用擴展來組織代碼
