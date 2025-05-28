import Foundation

/// 睡眠記錄視圖模型
class SleepRecordViewModel {
    // MARK: - 屬性
    
    /// 開始時間
    var startTime: Date = Date()
    
    /// 結束時間
    var endTime: Date = Date().addingTimeInterval(28800) // 默認8小時後
    
    /// 環境因素選項
    var environmentFactorsOption: Int = 0
    
    /// 睡眠中斷選項
    var sleepInterruptionOption: Int = 0
    
    /// 睡眠質量
    var sleepQuality: Int = 2
    
    /// 備註
    var notes: String = ""
    
    /// 保存完成處理器
    var onSaveCompleted: ((Result<Void, Error>) -> Void)?
    
    /// 睡眠記錄倉庫
    private let sleepRepository: SleepRecordRepository
    
    /// 用戶設置
    private let userSettings: UserSettings
    
    // MARK: - 初始化
    
    /// 初始化方法
    /// - Parameters:
    ///   - sleepRepository: 睡眠記錄倉庫
    ///   - userSettings: 用戶設置
    init(sleepRepository: SleepRecordRepository = DependencyContainer.shared.resolve(SleepRecordRepository.self)!,
         userSettings: UserSettings = DependencyContainer.shared.resolve(UserSettings.self)!) {
        self.sleepRepository = sleepRepository
        self.userSettings = userSettings
    }
    
    // MARK: - 公共方法
    
    /// 保存睡眠記錄
    func saveSleepRecord() {
        // 獲取選中的寶寶ID
        guard let babyId = userSettings.selectedBabyId else {
            // 處理錯誤
            onSaveCompleted?(.failure(RepositoryError.invalidData))
            return
        }
        
        // 檢查時間
        guard endTime > startTime else {
            // 處理錯誤
            onSaveCompleted?(.failure(NSError(domain: "SleepRecordViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "結束時間必須晚於開始時間"])))
            return
        }
        
        // 創建環境因素
        let environmentFactors = createEnvironmentFactors()
        
        // 創建睡眠中斷
        let sleepInterruption = createSleepInterruption()
        
        // 創建睡眠質量
        let quality = convertToSleepQuality(sleepQuality)
        
        // 計算持續時間
        let duration = endTime.timeIntervalSince(startTime)
        
        // 創建睡眠記錄
        let sleepRecord = SleepRecord(
            id: UUID().uuidString,
            babyId: babyId,
            startTime: startTime,
            endTime: endTime,
            quality: quality,
            environmentFactors: environmentFactors,
            interruptions: sleepInterruption,
            notes: notes.isEmpty ? nil : notes
        )
        
        // 保存睡眠記錄
        sleepRepository.addSleepRecord(sleepRecord) { [weak self] result in
            guard let self = self else { return }
            
            // 通知保存完成
            self.onSaveCompleted?(result.map { _ in () })
        }
    }
    
    // MARK: - 私有方法
    
    /// 創建環境因素
    private func createEnvironmentFactors() -> EnvironmentFactors? {
        guard let option = EnvironmentFactorsOption(rawValue: environmentFactorsOption), option != .none else {
            return nil
        }
        
        switch option {
        case .none:
            return nil
        case .noise:
            return EnvironmentFactors(noiseLevel: 50)
        case .light:
            return EnvironmentFactors(lightLevel: 50)
        case .temperature:
            return EnvironmentFactors(temperature: 25.0)
        case .other:
            return EnvironmentFactors(humidity: 50.0)
        }
    }
    
    /// 創建睡眠中斷
    private func createSleepInterruption() -> SleepInterruption? {
        guard let option = SleepInterruptionOption(rawValue: sleepInterruptionOption), option != .none else {
            return nil
        }
        
        let duration: TimeInterval = 900 // 默認15分鐘
        
        switch option {
        case .none:
            return nil
        case .crying:
            return SleepInterruption(duration: duration, reason: "哭鬧")
        case .feeding:
            return SleepInterruption(duration: duration, reason: "餵食")
        case .diaper:
            return SleepInterruption(duration: duration, reason: "換尿布")
        case .other:
            return SleepInterruption(duration: duration, reason: "其他")
        }
    }
    
    /// 轉換為睡眠質量枚舉
    private func convertToSleepQuality(_ index: Int) -> Int {
        switch index {
        case 0:
            return 1  // 很差
        case 1:
            return 2  // 一般
        case 2:
            return 3  // 良好
        case 3:
            return 4  // 優秀
        case 4:
            return 5  // 極佳
        default:
            return 3  // 默認良好
        }
    }
}

/// 睡眠質量枚舉
enum SleepQuality: String, Codable {
    case poor = "poor"
    case fair = "fair"
    case good = "good"
    case excellent = "excellent"
}
