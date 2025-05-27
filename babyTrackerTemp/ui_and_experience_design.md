# 寶寶生活記錄專業版（Baby Tracker）- 第二階段：用戶界面與基礎體驗

## 1. 用戶界面設計概述

在第二階段，我們將專注於實現應用的用戶界面和基礎體驗，包括主頁/儀表板界面、睡眠記錄流程與界面，以及基本的數據視覺化功能。設計將遵循溫馨親子風格，並特別考慮新手父母在疲勞狀態下的使用便利性。

### 1.1 設計原則

- **簡潔直觀**：界面元素簡化，減少認知負擔
- **大按鈕設計**：便於單手操作和疲勞狀態下使用
- **溫馨色調**：採用柔和、舒適的色彩方案
- **一致性**：保持視覺和交互模式的一致
- **即時反饋**：提供清晰的操作反饋
- **夜間友好**：特別優化夜間使用體驗

### 1.2 色彩方案

```swift
// 主色調
static let primaryColor = Color(hex: "6B8EAE") // 溫和天藍色
static let secondaryColor = Color(hex: "F0C8D0") // 柔和粉色
static let accentColor = Color(hex: "A7D7C9") // 薄荷綠

// 功能色彩
static let sleepColor = Color(hex: "8B9EB7") // 寧靜藍
static let feedingColor = Color(hex: "F3B391") // 溫暖橙
static let diaperColor = Color(hex: "D6A2E8") // 溫和紫

// 狀態色彩
static let successColor = Color(hex: "7FC8A9") // 柔和綠
static let warningColor = Color(hex: "FFD384") // 溫和黃
static let errorColor = Color(hex: "F5A7A7") // 柔和紅
static let disabledColor = Color(hex: "D1D1D6") // 柔和灰

// 背景色彩
static let backgroundColor = Color(hex: "FFFFFF") // 純白
static let secondaryBackgroundColor = Color(hex: "F8F9FA") // 淺灰白
static let darkBackgroundColor = Color(hex: "2C3E50") // 深藍灰（夜間模式）
```

### 1.3 排版系統

```swift
// 字體大小
enum FontSize {
    static let largeTitle: CGFloat = 24
    static let title: CGFloat = 20
    static let subtitle: CGFloat = 17
    static let body: CGFloat = 15
    static let caption: CGFloat = 13
    static let small: CGFloat = 11
}

// 字重
enum FontWeight {
    case regular
    case medium
    case semibold
    
    var uiFont: UIFont.Weight {
        switch self {
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        }
    }
}

// 文本樣式
struct TextStyle {
    let size: CGFloat
    let weight: FontWeight
    let color: Color
    
    static let largeTitle = TextStyle(size: FontSize.largeTitle, weight: .semibold, color: .primary)
    static let title = TextStyle(size: FontSize.title, weight: .semibold, color: .primary)
    static let subtitle = TextStyle(size: FontSize.subtitle, weight: .medium, color: .primary)
    static let body = TextStyle(size: FontSize.body, weight: .regular, color: .primary)
    static let caption = TextStyle(size: FontSize.caption, weight: .regular, color: .secondary)
    static let small = TextStyle(size: FontSize.small, weight: .regular, color: .secondary)
}
```

## 2. 主頁/儀表板界面

### 2.1 主頁設計

主頁是用戶最常訪問的界面，設計為卡片式布局，提供寶寶當前狀態、最近活動和快速操作。

```swift
struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 寶寶選擇器
                    babySelector
                    
                    // 當前狀態卡片
                    currentStatusCard
                    
                    // 睡眠記錄按鈕
                    sleepRecordButton
                    
                    // 今日睡眠摘要
                    todaySleepSummaryCard
                    
                    // 最近活動時間線
                    recentActivitiesTimeline
                    
                    // 智能建議卡片（預留）
                    recommendationCard
                }
                .padding()
            }
            .background(colorScheme == .dark ? Color.darkBackgroundColor : Color.secondaryBackgroundColor)
            .navigationTitle("主頁")
            .navigationBarItems(trailing: settingsButton)
        }
    }
    
    // 寶寶選擇器
    private var babySelector: some View {
        HStack {
            if let currentBaby = viewModel.currentBaby {
                Image(uiImage: currentBaby.photo ?? UIImage(named: "baby_placeholder")!)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                Text(currentBaby.name)
                    .font(.system(size: FontSize.subtitle, weight: .medium))
                
                Spacer()
                
                Button(action: {
                    viewModel.showBabySelector = true
                }) {
                    Image(systemName: "chevron.down.circle.fill")
                        .foregroundColor(.accentColor)
                }
            } else {
                Button(action: {
                    viewModel.showAddBaby = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("添加寶寶")
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
        .padding()
        .background(Color.backgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $viewModel.showBabySelector) {
            BabySelectorView(viewModel: viewModel.babySelectorViewModel)
        }
        .sheet(isPresented: $viewModel.showAddBaby) {
            AddBabyView(viewModel: viewModel.addBabyViewModel)
        }
    }
    
    // 當前狀態卡片
    private var currentStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("當前狀態")
                .font(.system(size: FontSize.subtitle, weight: .semibold))
            
            HStack(spacing: 20) {
                statusItem(
                    icon: "moon.fill",
                    color: .sleepColor,
                    title: "睡眠",
                    value: viewModel.isSleeping ? "睡眠中" : "清醒"
                )
                
                statusItem(
                    icon: "clock.fill",
                    color: .primaryColor,
                    title: "上次睡眠",
                    value: viewModel.lastSleepTime
                )
                
                statusItem(
                    icon: "bolt.fill",
                    color: .accentColor,
                    title: "睡眠質量",
                    value: viewModel.lastSleepQuality
                )
            }
        }
        .padding()
        .background(Color.backgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // 狀態項目
    private func statusItem(icon: String, color: Color, title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: FontSize.caption))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: FontSize.body, weight: .medium))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // 睡眠記錄按鈕
    private var sleepRecordButton: some View {
        Button(action: {
            if viewModel.isSleeping {
                viewModel.endSleep()
            } else {
                viewModel.startSleep()
            }
        }) {
            HStack {
                Image(systemName: viewModel.isSleeping ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 24))
                
                Text(viewModel.isSleeping ? "結束睡眠" : "開始睡眠")
                    .font(.system(size: FontSize.subtitle, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isSleeping ? Color.errorColor : Color.sleepColor)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .disabled(viewModel.currentBaby == nil)
        .opacity(viewModel.currentBaby == nil ? 0.5 : 1)
    }
    
    // 今日睡眠摘要卡片
    private var todaySleepSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日睡眠")
                .font(.system(size: FontSize.subtitle, weight: .semibold))
            
            HStack(spacing: 20) {
                summaryItem(
                    title: "總時長",
                    value: viewModel.todayTotalSleepTime,
                    icon: "hourglass",
                    color: .sleepColor
                )
                
                summaryItem(
                    title: "次數",
                    value: viewModel.todaySleepCount,
                    icon: "number",
                    color: .primaryColor
                )
                
                summaryItem(
                    title: "平均質量",
                    value: viewModel.todayAverageSleepQuality,
                    icon: "star.fill",
                    color: .accentColor
                )
            }
            
            // 簡單的睡眠時間分布圖
            sleepDistributionChart
        }
        .padding()
        .background(Color.backgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // 摘要項目
    private func summaryItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: FontSize.caption))
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: FontSize.body, weight: .medium))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // 睡眠分布圖
    private var sleepDistributionChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("睡眠分布")
                .font(.system(size: FontSize.caption))
                .foregroundColor(.secondary)
            
            GeometryReader { geometry in
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(0..<24, id: \.self) { hour in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(viewModel.sleepHours.contains(hour) ? Color.sleepColor : Color.clear)
                                .frame(height: viewModel.sleepHours.contains(hour) ? 20 : 0)
                            
                            if hour % 6 == 0 {
                                Text("\(hour)")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                            } else {
                                Spacer()
                                    .frame(height: 10)
                            }
                        }
                        .frame(width: (geometry.size.width - 48) / 24)
                    }
                }
                .frame(height: 40)
            }
            .frame(height: 40)
        }
    }
    
    // 最近活動時間線
    private var recentActivitiesTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近活動")
                .font(.system(size: FontSize.subtitle, weight: .semibold))
            
            if viewModel.recentActivities.isEmpty {
                HStack {
                    Spacer()
                    Text("暫無活動記錄")
                        .font(.system(size: FontSize.body))
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                }
            } else {
                ForEach(viewModel.recentActivities) { activity in
                    activityItem(activity: activity)
                }
            }
        }
        .padding()
        .background(Color.backgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // 活動項目
    private func activityItem(activity: ActivityViewModel) -> some View {
        HStack(spacing: 12) {
            // 活動類型圖標
            Image(systemName: activity.icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(activity.color)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.system(size: FontSize.body, weight: .medium))
                
                Text(activity.timeDescription)
                    .font(.system(size: FontSize.caption))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 活動詳情按鈕
            Button(action: {
                viewModel.showActivityDetail(activity: activity)
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    // 智能建議卡片（預留）
    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("智能建議")
                .font(.system(size: FontSize.subtitle, weight: .semibold))
            
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.warningColor)
                
                Text("根據寶寶的睡眠模式，建議在晚上7:30-8:00之間安排入睡")
                    .font(.system(size: FontSize.body))
                    .foregroundColor(.primary)
            }
            .padding()
            .background(Color.warningColor.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.backgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // 設置按鈕
    private var settingsButton: some View {
        Button(action: {
            viewModel.showSettings = true
        }) {
            Image(systemName: "gear")
                .foregroundColor(.primary)
        }
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView(viewModel: viewModel.settingsViewModel)
        }
    }
}
```

### 2.2 主頁視圖模型

```swift
class HomeViewModel: ObservableObject {
    // 發布屬性
    @Published var currentBaby: BabyViewModel?
    @Published var isSleeping: Bool = false
    @Published var lastSleepTime: String = "3小時前"
    @Published var lastSleepQuality: String = "良好"
    @Published var todayTotalSleepTime: String = "5小時30分"
    @Published var todaySleepCount: String = "3次"
    @Published var todayAverageSleepQuality: String = "4.0"
    @Published var sleepHours: [Int] = [0, 1, 2, 9, 10, 13, 14, 20, 21, 22, 23] // 示例數據
    @Published var recentActivities: [ActivityViewModel] = []
    
    // 導航狀態
    @Published var showBabySelector: Bool = false
    @Published var showAddBaby: Bool = false
    @Published var showSettings: Bool = false
    
    // 依賴
    private let babyRepository: BabyRepositoryProtocol
    private let sleepRepository: SleepRepositoryProtocol
    private let sleepUseCases: SleepUseCases
    
    // 子視圖模型
    lazy var babySelectorViewModel = BabySelectorViewModel(babyRepository: babyRepository, onSelect: { [weak self] baby in
        self?.selectBaby(baby: baby)
    })
    
    lazy var addBabyViewModel = AddBabyViewModel(babyRepository: babyRepository, onAdd: { [weak self] baby in
        self?.selectBaby(baby: baby)
    })
    
    lazy var settingsViewModel = SettingsViewModel()
    
    // 初始化
    init(babyRepository: BabyRepositoryProtocol, sleepRepository: SleepRepositoryProtocol, sleepUseCases: SleepUseCases) {
        self.babyRepository = babyRepository
        self.sleepRepository = sleepRepository
        self.sleepUseCases = sleepUseCases
        
        loadInitialData()
    }
    
    // 加載初始數據
    private func loadInitialData() {
        // 獲取所有寶寶
        let babies = babyRepository.getAllBabies()
   
(Content truncated due to size limit. Use line ranges to read in chunks)