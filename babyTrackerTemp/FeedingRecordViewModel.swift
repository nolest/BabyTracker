import Foundation

/// 餵食記錄視圖模型
class FeedingRecordViewModel {
    // MARK: - 屬性
    
    /// 開始時間
    var startTime: Date = Date()
    
    /// 結束時間
    var endTime: Date = Date().addingTimeInterval(1800) // 默認30分鐘後
    
    /// 餵食類型
    var feedingType: FeedingType = .breastfeeding
    
    /// 數量（毫升）
    var amount: Double?
    
    /// 備註
    var notes: String = ""
    
    /// 保存完成處理器
    var onSaveCompleted: ((Result<Void, Error>) -> Void)?
    
    /// 餵食倉庫
    private let feedingRepository: FeedingRepository
    
    /// 用戶設置
    private let userSettings: UserSettings
    
    // MARK: - 初始化
    
    /// 初始化方法
    /// - Parameters:
    ///   - feedingRepository: 餵食倉庫
    ///   - userSettings: 用戶設置
    init(feedingRepository: FeedingRepository = DependencyContainer.shared.resolve(FeedingRepository.self)!,
         userSettings: UserSettings = DependencyContainer.shared.resolve(UserSettings.self)!) {
        self.feedingRepository = feedingRepository
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
            onSaveCompleted?(.failure(NSError(domain: "FeedingRecordViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "結束時間必須晚於開始時間"])))
            return
        }
        
        // 檢查數量
        if feedingType == .bottleBreastMilk || feedingType == .formula {
            guard amount != nil else {
                // 處理錯誤
                onSaveCompleted?(.failure(NSError(domain: "FeedingRecordViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "請輸入餵食數量"])))
                return
            }
        }
        
        // 計算持續時間
        let duration = endTime.timeIntervalSince(startTime)
        
        // 創建餵食記錄
        let feedingRecord = FeedingRecord(
            id: UUID().uuidString,
            babyId: babyId,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            type: feedingType,
            amount: amount,
            notes: notes.isEmpty ? nil : notes
        )
        
        // 保存餵食記錄
        feedingRepository.addFeedingRecord(feedingRecord) { [weak self] result in
            guard let self = self else { return }
            
            // 通知保存完成
            self.onSaveCompleted?(result.map { _ in () })
        }
    }
}
