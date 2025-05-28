import Foundation

/// 睡眠記錄視圖模型
class SleepRecordViewModel {
    // MARK: - 屬性
    
    /// 開始時間
    var startTime: Date = Date()
    
    /// 結束時間
    var endTime: Date = Date().addingTimeInterval(28800) // 默認8小時後
    
    /// 環境因素
    var environmentFactors: EnvironmentFactors = .none
    
    /// 睡眠中斷
    var sleepInterruption: SleepInterruption = .none
    
    /// 睡眠質量
    var sleepQuality: SleepQuality = .good
    
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
    
    /// 保存記錄
    func saveRecord() {
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
        
        // 計算持續時間
        let duration = endTime.timeIntervalSince(startTime)
        
        // 創建睡眠記錄
        let sleepRecord = SleepRecord(
            id: UUID().uuidString,
            babyId: babyId,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            environmentFactors: environmentFactors == .none ? nil : environmentFactors,
            sleepInterruption: sleepInterruption == .none ? nil : sleepInterruption,
            quality: sleepQuality,
            notes: notes.isEmpty ? nil : notes
        )
        
        // 保存睡眠記錄
        sleepRepository.addSleepRecord(sleepRecord) { [weak self] result in
            guard let self = self else { return }
            
            // 通知保存完成
            self.onSaveCompleted?(result.map { _ in () })
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
