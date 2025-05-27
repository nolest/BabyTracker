import Foundation

/// 寶寶信息倉庫協議
protocol BabyRepository {
    /// 獲取所有寶寶
    /// - Parameter completion: 完成回調
    func getAllBabies(completion: @escaping (Result<[Baby], RepositoryError>) -> Void)
    
    /// 獲取寶寶
    /// - Parameters:
    ///   - id: 寶寶ID
    ///   - completion: 完成回調
    func getBaby(id: String, completion: @escaping (Result<Baby, RepositoryError>) -> Void)
    
    /// 添加寶寶
    /// - Parameters:
    ///   - baby: 寶寶信息
    ///   - completion: 完成回調
    func addBaby(_ baby: Baby, completion: @escaping (Result<Baby, RepositoryError>) -> Void)
    
    /// 更新寶寶
    /// - Parameters:
    ///   - baby: 寶寶信息
    ///   - completion: 完成回調
    func updateBaby(_ baby: Baby, completion: @escaping (Result<Baby, RepositoryError>) -> Void)
    
    /// 刪除寶寶
    /// - Parameters:
    ///   - id: 寶寶ID
    ///   - completion: 完成回調
    func deleteBaby(id: String, completion: @escaping (Result<Void, RepositoryError>) -> Void)
}

/// 寶寶信息倉庫實現
class BabyRepositoryImpl: BabyRepository {
    // MARK: - 單例
    
    /// 共享實例
    static let shared = BabyRepositoryImpl()
    
    // MARK: - 屬性
    
    /// 寶寶數據
    private var babies: [Baby] = []
    
    // MARK: - 初始化
    
    /// 初始化方法
    init() {
        // 加載示例數據
        loadSampleData()
    }
    
    // MARK: - BabyRepository
    
    func getAllBabies(completion: @escaping (Result<[Baby], RepositoryError>) -> Void) {
        // 模擬異步操作
        DispatchQueue.global().async {
            // 返回所有寶寶
            DispatchQueue.main.async {
                completion(.success(self.babies))
            }
        }
    }
    
    func getBaby(id: String, completion: @escaping (Result<Baby, RepositoryError>) -> Void) {
        // 模擬異步操作
        DispatchQueue.global().async {
            // 查找寶寶
            if let baby = self.babies.first(where: { $0.id == id }) {
                // 返回寶寶
                DispatchQueue.main.async {
                    completion(.success(baby))
                }
            } else {
                // 返回錯誤
                DispatchQueue.main.async {
                    completion(.failure(.notFound))
                }
            }
        }
    }
    
    func addBaby(_ baby: Baby, completion: @escaping (Result<Baby, RepositoryError>) -> Void) {
        // 模擬異步操作
        DispatchQueue.global().async {
            // 檢查是否已存在
            if self.babies.contains(where: { $0.id == baby.id }) {
                // 返回錯誤
                DispatchQueue.main.async {
                    completion(.failure(.duplicateData))
                }
                return
            }
            
            // 添加寶寶
            self.babies.append(baby)
            
            // 返回寶寶
            DispatchQueue.main.async {
                completion(.success(baby))
            }
        }
    }
    
    func updateBaby(_ baby: Baby, completion: @escaping (Result<Baby, RepositoryError>) -> Void) {
        // 模擬異步操作
        DispatchQueue.global().async {
            // 查找寶寶索引
            if let index = self.babies.firstIndex(where: { $0.id == baby.id }) {
                // 更新寶寶
                self.babies[index] = baby
                
                // 返回寶寶
                DispatchQueue.main.async {
                    completion(.success(baby))
                }
            } else {
                // 返回錯誤
                DispatchQueue.main.async {
                    completion(.failure(.notFound))
                }
            }
        }
    }
    
    func deleteBaby(id: String, completion: @escaping (Result<Void, RepositoryError>) -> Void) {
        // 模擬異步操作
        DispatchQueue.global().async {
            // 查找寶寶索引
            if let index = self.babies.firstIndex(where: { $0.id == id }) {
                // 刪除寶寶
                self.babies.remove(at: index)
                
                // 返回成功
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } else {
                // 返回錯誤
                DispatchQueue.main.async {
                    completion(.failure(.notFound))
                }
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 加載示例數據
    private func loadSampleData() {
        // 創建示例寶寶
        let calendar = Calendar.current
        let birthDate1 = calendar.date(byAdding: .month, value: -6, to: Date())!
        let birthDate2 = calendar.date(byAdding: .month, value: -12, to: Date())!
        
        let baby1 = Baby(
            id: "1",
            name: "小明",
            birthDate: birthDate1,
            gender: .male,
            photoURL: nil
        )
        
        let baby2 = Baby(
            id: "2",
            name: "小花",
            birthDate: birthDate2,
            gender: .female,
            photoURL: nil
        )
        
        // 添加示例寶寶
        babies = [baby1, baby2]
    }
}
