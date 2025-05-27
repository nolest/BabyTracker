import Foundation
import Combine

/// 活動列表視圖模型
class ActivitiesListViewModel {
    // MARK: - 屬性
    
    /// 活動倉庫
    private let activityRepository: ActivityRepository
    
    /// 取消令牌集合
    private var cancellables = Set<AnyCancellable>()
    
    /// 活動列表
    private(set) var activities: [Activity] = []
    
    /// 數據加載完成回調
    var onDataLoaded: (() -> Void)?
    
    /// 錯誤回調
    var onError: ((Error) -> Void)?
    
    // MARK: - 初始化
    
    /// 初始化方法
    /// - Parameter activityRepository: 活動倉庫
    init(activityRepository: ActivityRepository) {
        self.activityRepository = activityRepository
    }
    
    // MARK: - 公共方法
    
    /// 加載活動
    func loadActivities() {
        // 獲取過去30天的活動記錄
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        
        activityRepository.getActivities(from: startDate, to: endDate)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.onError?(error)
                    }
                },
                receiveValue: { [weak self] activities in
                    self?.activities = activities.sorted(by: { $0.startTime > $1.startTime })
                    self?.onDataLoaded?()
                }
            )
            .store(in: &cancellables)
    }
    
    /// 刪除活動
    /// - Parameters:
    ///   - activity: 要刪除的活動
    ///   - completion: 完成回調
    func deleteActivity(_ activity: Activity, completion: @escaping (Result<Void, Error>) -> Void) {
        activityRepository.deleteActivity(activity)
            .sink(
                receiveCompletion: { completionStatus in
                    switch completionStatus {
                    case .finished:
                        // 從活動列表中移除
                        if let index = self.activities.firstIndex(where: { $0.id == activity.id }) {
                            self.activities.remove(at: index)
                        }
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    /// 按類型過濾活動
    /// - Parameter type: 活動類型
    /// - Returns: 過濾後的活動列表
    func filterActivities(by type: ActivityType?) -> [Activity] {
        guard let type = type else {
            return activities
        }
        
        return activities.filter { $0.type == type }
    }
    
    /// 按日期範圍過濾活動
    /// - Parameters:
    ///   - startDate: 開始日期
    ///   - endDate: 結束日期
    /// - Returns: 過濾後的活動列表
    func filterActivities(from startDate: Date, to endDate: Date) -> [Activity] {
        return activities.filter { activity in
            activity.startTime >= startDate && activity.startTime <= endDate
        }
    }
}
