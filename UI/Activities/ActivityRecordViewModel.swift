import Foundation

/// 活動記錄視圖模型
class ActivityRecordViewModel {
    // MARK: - 屬性
    
    /// 開始時間
    var startTime: Date = Date()
    
    /// 結束時間
    var endTime: Date = Date().addingTimeInterval(1800) // 默認30分鐘後
    
    /// 活動類型
    var activityType: ActivityType = .diaper
    
    /// 活動名稱
    var activityName: String = "尿布更換"
    
    /// 備註
    var notes: String = ""
    
    /// 保存完成處理器
    var onSaveCompleted: ((Result<Void, Error>) -> Void)?
    
    /// 活動倉庫
    private let activityRepository: ActivityRepository
    
    /// 用戶設置
    private let userSettings: UserSettings
    
    // MARK: - 初始化
    
    /// 初始化方法
    /// - Parameters:
    ///   - activityRepository: 活動倉庫
    ///   - userSettings: 用戶設置
    init(activityRepository: ActivityRepository = DependencyContainer.shared.resolve(ActivityRepository.self)!,
         userSettings: UserSettings = DependencyContainer.shared.resolve(UserSettings.self)!) {
        self.activityRepository = activityRepository
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
            onSaveCompleted?(.failure(NSError(domain: "ActivityRecordViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "結束時間必須晚於開始時間"])))
            return
        }
        
        // 檢查活動名稱
        guard !activityName.isEmpty else {
            // 處理錯誤
            onSaveCompleted?(.failure(NSError(domain: "ActivityRecordViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "請輸入活動名稱"])))
            return
        }
        
        // 創建活動記錄
        let activity = Activity(
            id: UUID().uuidString,
            babyId: babyId,
            type: activityType,
            startTime: startTime,
            endTime: endTime,
            notes: notes.isEmpty ? nil : notes
        )
        
        // 保存活動記錄
        activityRepository.createActivity(activity) { [weak self] result in
            guard let self = self else { return }
            
            // 通知保存完成
            self.onSaveCompleted?(result)
        }
    }
}
