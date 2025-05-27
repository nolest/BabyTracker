import Foundation
import Combine

/// 活動詳情視圖模型
class ActivityDetailViewModel {
    // MARK: - 屬性
    
    /// 活動
    let activity: Activity
    
    /// 活動倉庫
    private let activityRepository: ActivityRepository?
    
    /// 取消令牌集合
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    
    /// 初始化方法
    /// - Parameters:
    ///   - activity: 活動
    ///   - activityRepository: 活動倉庫（可選）
    init(activity: Activity, activityRepository: ActivityRepository? = nil) {
        self.activity = activity
        self.activityRepository = activityRepository ?? DependencyContainer.shared.resolve(ActivityRepository.self)
    }
    
    // MARK: - 公共方法
    
    /// 刪除活動
    /// - Parameter completion: 完成回調
    func deleteActivity(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let activityRepository = activityRepository else {
            completion(.failure(RepositoryError.repositoryNotAvailable))
            return
        }
        
        activityRepository.deleteActivity(activity)
            .sink(
                receiveCompletion: { completionStatus in
                    switch completionStatus {
                    case .finished:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
}
