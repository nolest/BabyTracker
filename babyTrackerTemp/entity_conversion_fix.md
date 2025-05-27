# 寶寶生活記錄專業版（Baby Tracker）- 添加實體轉換方法

## 1. 問題描述

在第一階段與第二階段整合性驗證中，發現部分ViewModel缺少完整的實體轉換方法，特別是從ViewModel轉換回領域實體（Domain Entity）的方法。這種不完整的轉換機制會導致以下問題：

1. 數據流不完整，無法保證視圖層數據能正確回寫到數據層
2. 編輯功能受限，因為無法將修改後的ViewModel數據轉換回實體進行保存
3. 代碼重複，每個需要轉換的地方都需要手動映射屬性
4. 數據一致性風險，手動映射容易遺漏屬性或映射錯誤
5. 第三階段AI分析功能可能無法獲取完整的用戶修改數據

## 2. 修正方案

### 2.1 定義通用的實體轉換協議

首先，定義一個通用的實體轉換協議，所有ViewModel都應實現該協議：

```swift
// EntityConvertible.swift

protocol EntityConvertible {
    associatedtype Entity
    
    // 從實體創建ViewModel
    init(entity: Entity, dependencies: Any...)
    
    // 將ViewModel轉換為實體
    func toEntity() -> Entity
}
```

### 2.2 為BabyViewModel添加實體轉換方法

```swift
// BabyViewModel.swift

class BabyViewModel: ObservableObject, Identifiable, EntityConvertible {
    typealias Entity = Baby
    
    let id: UUID
    @Published var name: String
    @Published var birthDate: Date
    @Published var gender: Gender
    @Published var avatarUrl: URL?
    @Published var notes: String
    let createdAt: Date
    @Published var updatedAt: Date
    
    @Published var isLoading: Bool = false
    
    private let saveBabyUseCase: SaveBabyUseCase
    private let errorHandler: ErrorHandlingService
    
    // 從實體創建ViewModel
    init(baby: Baby, saveBabyUseCase: SaveBabyUseCase, errorHandler: ErrorHandlingService) {
        self.id = baby.id
        self.name = baby.name
        self.birthDate = baby.birthDate
        self.gender = baby.gender
        self.avatarUrl = baby.avatarUrl
        self.notes = baby.notes
        self.createdAt = baby.createdAt
        self.updatedAt = baby.updatedAt
        self.saveBabyUseCase = saveBabyUseCase
        self.errorHandler = errorHandler
    }
    
    // 創建新寶寶
    init(id: UUID = UUID(),
         name: String = "",
         birthDate: Date = Date(),
         gender: Gender = .unknown,
         avatarUrl: URL? = nil,
         notes: String = "",
         saveBabyUseCase: SaveBabyUseCase,
         errorHandler: ErrorHandlingService) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.gender = gender
        self.avatarUrl = avatarUrl
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
        self.saveBabyUseCase = saveBabyUseCase
        self.errorHandler = errorHandler
    }
    
    // 將ViewModel轉換為實體
    func toEntity() -> Baby {
        return Baby(
            id: id,
            name: name,
            birthDate: birthDate,
            gender: gender,
            avatarUrl: avatarUrl,
            notes: notes,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
    
    // 保存寶寶
    func saveBaby(completion: @escaping () -> Void) {
        isLoading = true
        
        let baby = toEntity()
        
        saveBabyUseCase.execute(baby: baby) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                self.errorHandler.handleResult(result) { _ in
                    self.updatedAt = Date()
                    completion()
                }
            }
        }
    }
    
    // 獲取寶寶年齡
    var age: String {
        let now = Date()
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year, .month, .day], from: birthDate, to: now)
        
        if let years = ageComponents.year, years > 0 {
            if let months = ageComponents.month, months > 0 {
                return "\(years)歲\(months)個月"
            } else {
                return "\(years)歲"
            }
        } else if let months = ageComponents.month, months > 0 {
            if let days = ageComponents.day, days > 0 {
                return "\(months)個月\(days)天"
            } else {
                return "\(months)個月"
            }
        } else if let days = ageComponents.day {
            return "\(days)天"
        } else {
            return "新生兒"
        }
    }
}
```

### 2.3 為SleepRecordViewModel添加實體轉換方法

```swift
// SleepRecordViewModel.swift

class SleepRecordViewModel: ObservableObject, Identifiable, EntityConvertible {
    typealias Entity = SleepRecord
    
    let id: UUID
    let babyId: UUID
    @Published var startTime: Date
    @Published var endTime: Date?
    @Published var quality: Int
    @Published var notes: String
    @Published var interruptions: [SleepInterruptionViewModel] = []
    @Published var environmentFactors: [EnvironmentFactorViewModel] = []
    let createdAt: Date
    @Published var updatedAt: Date
    
    @Published var isLoading: Bool = false
    
    private let saveSleepRecordUseCase: SaveSleepRecordUseCase
    private let errorHandler: ErrorHandlingService
    
    // 從實體創建ViewModel
    init(record: SleepRecord, saveSleepRecordUseCase: SaveSleepRecordUseCase, errorHandler: ErrorHandlingService) {
        self.id = record.id
        self.babyId = record.babyId
        self.startTime = record.startTime
        self.endTime = record.endTime
        self.quality = record.quality
        self.notes = record.notes
        self.createdAt = record.createdAt
        self.updatedAt = record.updatedAt
        self.saveSleepRecordUseCase = saveSleepRecordUseCase
        self.errorHandler = errorHandler
        
        // 轉換中斷記錄
        if let interruptions = record.interruptions {
            self.interruptions = interruptions.map { interruption in
                SleepInterruptionViewModel(interruption: interruption)
            }
        }
        
        // 轉換環境因素
        if let environmentFactors = record.environmentFactors {
            self.environmentFactors = environmentFactors.map { factor in
                EnvironmentFactorViewModel(factor: factor)
            }
        }
    }
    
    // 創建新睡眠記錄
    init(id: UUID = UUID(),
         babyId: UUID,
         startTime: Date = Date(),
         endTime: Date? = nil,
         quality: Int = 5,
         notes: String = "",
         saveSleepRecordUseCase: SaveSleepRecordUseCase,
         errorHandler: ErrorHandlingService) {
        self.id = id
        self.babyId = babyId
        self.startTime = startTime
        self.endTime = endTime
        self.quality = quality
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
        self.saveSleepRecordUseCase = saveSleepRecordUseCase
        self.errorHandler = errorHandler
    }
    
    // 將ViewModel轉換為實體
    func toEntity() -> SleepRecord {
        return SleepRecord(
            id: id,
            babyId: babyId,
            startTime: startTime,
            endTime: endTime,
            quality: quality,
            notes: notes,
            interruptions: interruptions.map { $0.toEntity() },
            environmentFactors: environmentFactors.map { $0.toEntity() },
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
    
    // 保存睡眠記錄
    func saveSleepRecord(completion: @escaping () -> Void) {
        isLoading = true
        
        let sleepRecord = toEntity()
        
        saveSleepRecordUseCase.execute(sleepRecord: sleepRecord) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                self.errorHandler.handleResult(result) { _ in
                    self.updatedAt = Date()
                    completion()
                }
            }
        }
    }
    
    // 開始睡眠
    func startSleep() {
        startTime = Date()
        endTime = nil
    }
    
    // 結束睡眠
    func endSleep() {
        endTime = Date()
    }
    
    // 添加中斷
    func addInterruption(reason: String, startTime: Date, endTime: Date? = nil) {
        let interruption = SleepInterruptionViewModel(
            sleepRecordId: id,
            reason: reason,
            startTime: startTime,
            endTime: endTime
        )
        interruptions.append(interruption)
    }
    
    // 添加環境因素
    func addEnvironmentFactor(type: EnvironmentFactorType, value: Int) {
        let factor = EnvironmentFactorViewModel(
            sleepRecordId: id,
            type: type,
            value: value
        )
        environmentFactors.append(factor)
    }
    
    // 獲取睡眠持續時間
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    // 格式化的持續時間
    var formattedDuration: String {
        guard let duration = duration else { return "進行中" }
        
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return String(format: "%d小時%02d分鐘", hours, minutes)
        } else {
            return String(format: "%d分鐘", minutes)
        }
    }
}
```

### 2.4 為SleepInterruptionViewModel添加實體轉換方法

```swift
// SleepInterruptionViewModel.swift

class SleepInterruptionViewModel: Identifiable, EntityConvertible {
    typealias Entity = SleepInterruption
    
    let id: UUID
    let sleepRecordId: UUID
    var reason: String
    var startTime: Date
    var endTime: Date?
    
    // 從實體創建ViewModel
    init(interruption: SleepInterruption) {
        self.id = interruption.id
        self.sleepRecordId = interruption.sleepRecordId
        self.reason = interruption.reason
        self.startTime = interruption.startTime
        self.endTime = interruption.endTime
    }
    
    // 創建新中斷記錄
    init(id: UUID = UUID(),
         sleepRecordId: UUID,
         reason: String,
         startTime: Date = Date(),
         endTime: Date? = nil) {
        self.id = id
        self.sleepRecordId = sleepRecordId
        self.reason = reason
        self.startTime = startTime
        self.endTime = endTime
    }
    
    // 將ViewModel轉換為實體
    func toEntity() -> SleepInterruption {
        return SleepInterruption(
            id: id,
            sleepRecordId: sleepRecordId,
            reason: reason,
            startTime: startTime,
            endTime: endTime
        )
    }
    
    // 獲取中斷持續時間
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    // 格式化的持續時間
    var formattedDuration: String {
        guard let duration = duration else { return "進行中" }
        
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        return String(format: "%d分%02d秒", minutes, seconds)
    }
}
```

### 2.5 為EnvironmentFactorViewModel添加實體轉換方法

```swift
// EnvironmentFactorViewModel.swift

class EnvironmentFactorViewModel: Identifiable, EntityConvertible {
    typealias Entity = EnvironmentFactor
    
    let id: UUID
    let sleepRecordId: UUID
    var type: EnvironmentFactorType
    var value: Int
    
    // 從實體創建ViewModel
    init(factor: EnvironmentFactor) {
        self.id = factor.id
        self.sleepRecordId = factor.sleepRecordId
        self.type = factor.type
        self.value = factor.value
    }
    
    // 創建新環境因素
    init(id: UUID = UUID(),
         sleepRecordId: UUID,
         type: EnvironmentFactorType,
         value: Int) {
        self.id = id
        self.sleepRecordId = sleepRecordId
        self.type = type
        self.value = value
    }
    
    // 將ViewModel轉換為實體
    func toEntity() -> EnvironmentFactor {
        return EnvironmentFactor(
            id: id,
            sleepRecordId: sleepRecordId,
            type: type,
            value: value
        )
    }
    
    // 獲取環境因素的本地化名稱
    var typeLocalizedName: String {
        switch type {
        case .light:
            return "光線"
        case .noise:
            return "噪音"
        case .temperature:
            return "溫度"
        case .humidity:
            return "濕度"
        }
    }
    
    // 獲取環境因素的圖標名稱
    var typeIconName: String {
        switch type {
        case .light:
            return "sun.max"
        case .noise:
            return "speaker.wave.3"
        case .temperature:
            return "thermometer"
        case .humidity:
            return "humidity"
        }
    }
    
    // 獲取環境因素的值描述
    var valueDescription: String {
        switch type {
        case .light:
            return lightValueDescription
        case .noise:
            return noiseValueDescription
        case .temperature:
            return temperatureValueDescription
        case .humidity:
            return humidityValueDescription
        }
    }
    
    // 光線值描述
    private var lightValueDescription: String {
        switch value {
        case 0...2:
            return "非常暗"
        case 3...4:
            return "較暗"
        case 5...6:
            return "適中"
        case 7...8:
            return "較亮"
        default:
            return "非常亮"
        }
    }
    
    // 噪音值描述
    private var noiseValueDescription: String {
        switch value {
        case 0...2:
            return "非常安靜"
        case 3...4:
            return "較安靜"
        case 5...6:
            return "適中"
        case 7...8:
            return "較吵"
        default:
            return "非常吵"
        }
    }
    
    // 溫度值描述
    private var temperatureValueDescription: String {
        switch value {
        case 0...2:
            return "非常冷"
        case 3...4:
            return "較冷"
        case 5...6:
            return "適中"
        case 7...8:
            return "較熱"
        default:
            return "非常熱"
        }
    }
    
    // 濕度值描述
    private var humidityValueDescription: String {
        switch value {
        case 0...2:
            return "非常乾燥"
        case 3...4:
            return "較乾燥"
        case 5...6:
            return "適中"
        case 7...8:
            return "較潮濕"
        default:
            return "非常潮濕"
        }
    }
}
```

### 2.6 為FeedingRecordViewModel添加實體轉換方法

```swift
// FeedingRecordViewModel.swift

enum FeedingType: String, CaseIterable {
    case breastfeeding = "breastfeeding"
    case bottleBreastMilk = "bottleBreastMilk"
    case formula = "formula"
    case solidFood = "solidFood"
}

class FeedingRecordViewModel: ObservableObject, Identifiable, EntityConvertible {
    typealias Entity = FeedingRecord
    
    let id: UUID
    let babyId: UUID
    @Published var type: FeedingType
    @Published var startTime: Date
    @Published var endTime: Date?
    @Published var amount: Double?
    @Published var unit: String?
    @Published var foodType: String?
    @Published var notes: String
    let createdAt: Date
    @Published var updatedAt: Date
    
    @Published var isLoading: Bool = false
    
    private let saveFeedingRecordUseCase: SaveFeedingRecordUseCase
    private let errorHandler: ErrorHandlingService
    
    // 從實體創建ViewModel
    init(record: FeedingRecord, saveFeedingRecordUseCase: SaveFeedingRecordUseCase, errorHandler: ErrorHandlingService) {
        self.id = record.id
        self.babyId = record.babyId
        self.type = FeedingType(rawValue: record.type) ?? .breastfeeding
        self.startTime = record.startTime
        self.endTime = record.endTime
        self.amount = record.amount
        self.unit = record.unit
        self.foodType = record.foodType
        self.notes = record.notes
        self.createdAt = record.createdAt
        self.updatedAt = record.updatedAt
        self.saveFeedingRecordUseCase = saveFeedingRecordUseCase
        self.errorHandler = errorHandler
    }
    
    // 創建新餵食記錄
    init(id: UUID = UUID(),
         babyId: UUID,
         type: FeedingType = .breastfeeding,
         startTime: Date = Date(),
         endTime: Date? = nil,
         amount: Double? = nil,
         unit: String? = nil,
         foodType: String? = nil,
         notes: String = "",
         saveFeedingRecordUseCase: SaveFeedingRecordUseCase,
         errorHandler: ErrorHandlingService) {
        self.id = id
        self.babyId = babyId
        self.type = type
        self.startTime = startTime
        self.e
(Content truncated due to size limit. Use line ranges to read in chunks)