import Foundation
import Combine

/// 成長記錄視圖模型
class GrowthRecordViewModel {
    // MARK: - 屬性
    
    /// 成長記錄倉庫
    private let growthRepository: GrowthRepository
    
    /// 是否為編輯模式
    let isEditing: Bool
    
    /// 成長記錄ID
    private let growthRecordId: String?
    
    /// 日期
    var date: Date
    
    /// 身高
    var height: Double?
    
    /// 體重
    var weight: Double?
    
    /// 頭圍
    var headCircumference: Double?
    
    /// 備註
    var notes: String?
    
    /// 取消令牌集合
    private var cancellables = Set<AnyCancellable>()
    
    /// 保存成功回調
    var onSaveSuccess: (() -> Void)?
    
    /// 保存錯誤回調
    var onSaveError: ((Error) -> Void)?
    
    // MARK: - 初始化
    
    /// 初始化方法（新增模式）
    /// - Parameter growthRepository: 成長記錄倉庫
    init(growthRepository: GrowthRepository) {
        self.growthRepository = growthRepository
        self.isEditing = false
        self.growthRecordId = nil
        self.date = Date()
    }
    
    /// 初始化方法（編輯模式）
    /// - Parameters:
    ///   - growthRepository: 成長記錄倉庫
    ///   - growthRecord: 成長記錄
    init(growthRepository: GrowthRepository, growthRecord: Growth) {
        self.growthRepository = growthRepository
        self.isEditing = true
        self.growthRecordId = growthRecord.id
        self.date = growthRecord.date
        self.height = growthRecord.height
        self.weight = growthRecord.weight
        self.headCircumference = growthRecord.headCircumference
        self.notes = growthRecord.notes
    }
    
    // MARK: - 公共方法
    
    /// 保存成長記錄
    /// - Parameters:
    ///   - date: 日期
    ///   - height: 身高
    ///   - weight: 體重
    ///   - headCircumference: 頭圍
    ///   - notes: 備註
    func saveGrowthRecord(date: Date, height: Double?, weight: Double?, headCircumference: Double?, notes: String?) {
        // 驗證輸入
        guard let height = height, let weight = weight else {
            onSaveError?(RepositoryError.invalidData("身高和體重為必填項"))
            return
        }
        
        // 創建成長記錄
        let growthRecord = Growth(
            id: growthRecordId ?? UUID().uuidString,
            date: date,
            height: height,
            weight: weight,
            headCircumference: headCircumference,
            notes: notes
        )
        
        // 保存成長記錄
        if isEditing {
            // 更新現有記錄
            growthRepository.updateGrowthRecord(growthRecord)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            self?.onSaveError?(error)
                        }
                    },
                    receiveValue: { [weak self] _ in
                        self?.onSaveSuccess?()
                    }
                )
                .store(in: &cancellables)
        } else {
            // 添加新記錄
            growthRepository.addGrowthRecord(growthRecord)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            self?.onSaveError?(error)
                        }
                    },
                    receiveValue: { [weak self] _ in
                        self?.onSaveSuccess?()
                    }
                )
                .store(in: &cancellables)
        }
    }
}
