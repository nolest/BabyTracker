import Foundation

/// 依賴注入容器
class DependencyContainer {
    // MARK: - 單例
    
    /// 共享實例
    static let shared = DependencyContainer()
    
    // MARK: - 屬性
    
    /// 依賴字典
    private var dependencies: [String: Any] = [:]
    
    // MARK: - 初始化
    
    /// 私有初始化方法
    private init() {
        registerDefaults()
    }
    
    // MARK: - 註冊
    
    /// 註冊依賴
    /// - Parameters:
    ///   - dependency: 依賴實例
    ///   - type: 依賴類型
    func register<T>(_ dependency: Any, for type: T.Type) {
        let key = String(describing: type)
        dependencies[key] = dependency
    }
    
    /// 註冊默認依賴
    private func registerDefaults() {
        // 註冊倉庫
        register(SleepRecordRepositoryImpl(), for: SleepRecordRepository.self)
        register(ActivityRepositoryImpl(), for: ActivityRepository.self)
        register(FeedingRepositoryImpl(), for: FeedingRepository.self)
        register(BabyRepositoryImpl(), for: BabyRepository.self)
        register(GrowthRepositoryImpl(), for: GrowthRepository.self)
        
        // 註冊服務
        register(NetworkMonitor(), for: NetworkMonitor.self)
        register(UserSettings(), for: UserSettings.self)
        register(DataAnonymizer(), for: DataAnonymizer.self)
        register(DeepseekAPIClient(), for: DeepseekAPIClient.self)
        register(CloudAIService(), for: CloudAIService.self)
        register(SleepPatternAnalyzer(), for: SleepPatternAnalyzer.self)
        register(RoutineAnalyzer(), for: RoutineAnalyzer.self)
        register(PredictionEngine(), for: PredictionEngine.self)
        register(AIEngine(), for: AIEngine.self)
        register(SyncService(), for: SyncService.self)
        register(NotificationService(), for: NotificationService.self)
        register(DataMigrationService(), for: DataMigrationService.self)
        register(BackupService(), for: BackupService.self)
        
        // 註冊安全
        register(APIKeyManager(), for: APIKeyManager.self)
        register(DeviceIdentifier(), for: DeviceIdentifier.self)
        register(UsageLimiter(), for: UsageLimiter.self)
    }
    
    // MARK: - 解析
    
    /// 解析依賴
    /// - Parameter type: 依賴類型
    /// - Returns: 依賴實例
    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        return dependencies[key] as? T
    }
    
    // MARK: - 重置
    
    /// 重置容器
    func reset() {
        dependencies.removeAll()
        registerDefaults()
    }
}

// MARK: - 倉庫實現

/// 睡眠記錄倉庫實現
class SleepRecordRepositoryImpl: SleepRecordRepository {
    func getSleepRecords(for babyId: String, from startDate: Date, to endDate: Date, completion: @escaping (Result<[SleepRecord], Error>) -> Void) {
        // 模擬數據
        let sleepRecords = [
            SleepRecord(id: UUID().uuidString, babyId: babyId, startTime: Date().addingTimeInterval(-3600), endTime: Date(), duration: 3600, quality: 0.8, environmentFactors: ["安靜", "黑暗"], interruptions: nil, notes: "睡得很好"),
            SleepRecord(id: UUID().uuidString, babyId: babyId, startTime: Date().addingTimeInterval(-7200), endTime: Date().addingTimeInterval(-3600), duration: 3600, quality: 0.7, environmentFactors: ["安靜"], interruptions: nil, notes: nil)
        ]
        completion(.success(sleepRecords))
    }
    
    func getSleepRecord(with id: String, completion: @escaping (Result<SleepRecord, Error>) -> Void) {
        // 模擬數據
        let sleepRecord = SleepRecord(id: id, babyId: "baby1", startTime: Date().addingTimeInterval(-3600), endTime: Date(), duration: 3600, quality: 0.8, environmentFactors: ["安靜", "黑暗"], interruptions: nil, notes: "睡得很好")
        completion(.success(sleepRecord))
    }
    
    func createSleepRecord(_ sleepRecord: SleepRecord, completion: @escaping (Result<Void, Error>) -> Void) {
        // 模擬創建
        completion(.success(()))
    }
    
    func updateSleepRecord(_ sleepRecord: SleepRecord, completion: @escaping (Result<Void, Error>) -> Void) {
        // 模擬更新
        completion(.success(()))
    }
    
    func deleteSleepRecord(with id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // 模擬刪除
        completion(.success(()))
    }
}

/// 活動倉庫實現
class ActivityRepositoryImpl: ActivityRepository {
    func getActivities(for babyId: String, from startDate: Date, to endDate: Date, completion: @escaping (Result<[Activity], Error>) -> Void) {
        // 模擬數據
        let activities = [
            Activity(id: UUID().uuidString, babyId: babyId, startTime: Date().addingTimeInterval(-3600), duration: 1800, type: .play, name: "玩積木", notes: "很開心"),
            Activity(id: UUID().uuidString, babyId: babyId, startTime: Date().addingTimeInterval(-7200), duration: 1200, type: .tummyTime, name: "趴著玩", notes: nil)
        ]
        completion(.success(activities))
    }
    
    func getActivity(with id: String, completion: @escaping (Result<Activity, Error>) -> Void) {
        // 模擬數據
        let activity = Activity(id: id, babyId: "baby1", startTime: Date().addingTimeInterval(-3600), duration: 1800, type: .play, name: "玩積木", notes: "很開心")
        completion(.success(activity))
    }
    
    func createActivity(_ activity: Activity, completion: @escaping (Result<Void, Error>) -> Void) {
        // 模擬創建
        completion(.success(()))
    }
    
    func updateActivity(_ activity: Activity, completion: @escaping (Result<Void, Error>) -> Void) {
        // 模擬更新
        completion(.success(()))
    }
    
    func deleteActivity(with id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // 模擬刪除
        completion(.success(()))
    }
}

/// 餵食倉庫實現
class FeedingRepositoryImpl: FeedingRepository {
    func getFeedingRecords(for babyId: String, from startDate: Date, to endDate: Date, completion: @escaping (Result<[FeedingRecord], Error>) -> Void) {
        // 模擬數據
        let feedingRecords = [
            FeedingRecord(id: UUID().uuidString, babyId: babyId, startTime: Date().addingTimeInterval(-3600), duration: 900, type: .breastfeeding, amount: nil, notes: "吃得很好"),
            FeedingRecord(id: UUID().uuidString, babyId: babyId, startTime: Date().addingTimeInterval(-7200), duration: 600, type: .formula, amount: 120, notes: nil)
        ]
        completion(.success(feedingRecords))
    }
    
    func getFeedingRecord(with id: String, completion: @escaping (Result<FeedingRecord, Error>) -> Void) {
        // 模擬數據
        let feedingRecord = FeedingRecord(id: id, babyId: "baby1", startTime: Date().addingTimeInterval(-3600), duration: 900, type: .breastfeeding, amount: nil, notes: "吃得很好")
        completion(.success(feedingRecord))
    }
    
    func createFeedingRecord(_ feedingRecord: FeedingRecord, completion: @escaping (Result<Void, Error>) -> Void) {
        // 模擬創建
        completion(.success(()))
    }
    
    func updateFeedingRecord(_ feedingRecord: FeedingRecord, completion: @escaping (Result<Void, Error>) -> Void) {
        // 模擬更新
        completion(.success(()))
    }
    
    func deleteFeedingRecord(with id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // 模擬刪除
        completion(.success(()))
    }
}

/// 寶寶倉庫實現
class BabyRepositoryImpl: BabyRepository {
    func getAllBabies(completion: @escaping (Result<[Baby], Error>) -> Void) {
        // 模擬數據
        let babies = [
            Baby(id: "baby1", name: "小明", birthDate: Date().addingTimeInterval(-60 * 60 * 24 * 30 * 6), gender: .male, photoURL: nil),
            Baby(id: "baby2", name: "小花", birthDate: Date().addingTimeInterval(-60 * 60 * 24 * 30 * 3), gender: .female, photoURL: nil)
        ]
        completion(.success(babies))
    }
    
    func getBaby(with id: String, completion: @escaping (Result<Baby, Error>) -> Void) {
        // 模擬數據
        let baby = Baby(id: id, name: "小明", birthDate: Date().addingTimeInterval(-60 * 60 * 24 * 30 * 6), gender: .male, photoURL: nil)
        completion(.success(baby))
    }
    
    func createBaby(_ baby: Baby, completion: @escaping (Result<Void, Error>) -> Void) {
        // 模擬創建
        completion(.success(()))
    }
    
    func updateBaby(_ baby: Baby, completion: @escaping (Result<Void, Error>) -> Void) {
        // 模擬更新
        completion(.success(()))
    }
    
    func deleteBaby(with id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // 模擬刪除
        completion(.success(()))
    }
}

/// 成長記錄倉庫實現
class GrowthRepositoryImpl: GrowthRepository {
    func getGrowthRecords(for babyId: String, completion: @escaping (Result<[Growth], Error>) -> Void) {
        // 模擬數據
        let growthRecords = [
            Growth(id: UUID().uuidString, babyId: babyId, date: Date().addingTimeInterval(-60 * 60 * 24 * 30), height: 65.5, weight: 7.2, headCircumference: 42.0),
            Growth(id: UUID().uuidString, babyId: babyId, date: Date(), height: 67.0, weight: 7.5, headCircumference: 42.5)
        ]
        completion(.success(growthRecords))
    }
    
    func getGrowthRecord(with id: String, completion: @escaping (Result<Growth, Error>) -> Void) {
        // 模擬數據
        let growthRecord = Growth(id: id, babyId: "baby1", date: Date(), height: 67.0, weight: 7.5, headCircumference: 42.5)
        completion(.success(growthRecord))
    }
    
    func createGrowthRecord(_ growthRecord: Growth, completion: @escaping (Result<Void, Error>) -> Void) {
        // 模擬創建
        completion(.success(()))
    }
    
    func updateGrowthRecord(_ growthRecord: Growth, completion: @escaping (Result<Void, Error>) -> Void) {
        // 模擬更新
        completion(.success(()))
    }
    
    func deleteGrowthRecord(with id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // 模擬刪除
        completion(.success(()))
    }
}
