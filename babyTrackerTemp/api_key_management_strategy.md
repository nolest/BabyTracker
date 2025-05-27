# 寶寶生活記錄專業版（Baby Tracker）- API Key 管理策略

## 1. 概述

本文檔詳細描述了「寶寶生活記錄專業版」應用在純客戶端環境下的 Deepseek API Key 管理與防濫用機制策略。該策略旨在保護 API Key 不被濫用或盜用，同時確保用戶能夠順暢地使用 AI 分析功能。

### 1.1 設計目標

- **安全性**：防止 API Key 被提取、濫用或盜用
- **可用性**：確保正常用戶能夠順暢使用 AI 分析功能
- **可維護性**：支持 API Key 的定期更新和管理
- **可擴展性**：支持未來可能的功能擴展和架構調整
- **合規性**：符合 Deepseek API 使用條款和限制

### 1.2 關鍵策略

1. **多 Key 輪換策略**：在應用中嵌入多個 API Key，並實現智能輪換機制
2. **安全存儲與保護**：使用多種技術保護嵌入的 API Key
3. **客戶端限流機制**：實現本地使用限制，防止過度使用
4. **智能緩存策略**：減少重複請求，優化 API 使用效率
5. **更新機制**：支持 API Key 的定期更新

## 2. 多 Key 輪換策略

### 2.1 API Key 數量與分配

應用將嵌入 5 個不同的 Deepseek API Key，採用混合分配策略：

#### 2.1.1 按用戶群體分配

- 基於設備 ID 的哈希值將用戶均勻分配到 3 個主要 API Key
- 分配算法：`keyIndex = hash(deviceID) % 3`
- 這確保了用戶負載均勻分佈在不同的 API Key 上

#### 2.1.2 按功能分配

- 為高頻使用的功能分配專用 API Key：
  - 睡眠分析：使用主要 API Key（按用戶分配的 3 個之一）
  - 作息分析：使用主要 API Key（按用戶分配的 3 個之一）
  - 預測功能：使用專用的第 4 個 API Key
  - 批量分析：使用專用的第 5 個 API Key

#### 2.1.3 動態負載均衡

- 監控本地記錄的 API 使用情況和錯誤率
- 當檢測到某個 API Key 可能達到限制時，臨時切換到備用 Key
- 實現指數退避算法處理 API 限流錯誤

### 2.2 輪換邏輯

輪換邏輯將考慮多種因素，以最大化 API 可用性：

#### 2.2.1 主要分配邏輯

```
function selectApiKey(deviceId, analysisType, usageHistory) {
    // 基本分配 - 按設備ID哈希
    let primaryKeyIndex = hash(deviceId) % 3;
    
    // 功能特定分配
    if (analysisType == "prediction") {
        return API_KEYS[3]; // 預測專用Key
    } else if (analysisType == "batch_analysis") {
        return API_KEYS[4]; // 批量分析專用Key
    }
    
    // 檢查主Key的使用情況
    if (isApproachingLimit(primaryKeyIndex, usageHistory)) {
        // 選擇負載最輕的備用Key
        return selectLeastLoadedKey(usageHistory, [0, 1, 2]);
    }
    
    return API_KEYS[primaryKeyIndex];
}
```

#### 2.2.2 負載檢測與平衡

- 記錄每個 API Key 的使用次數、時間分佈和錯誤率
- 當單個 Key 在短時間內使用頻率過高時，臨時切換到其他 Key
- 實現平滑的負載分配，避免任何單個 Key 被過度使用

#### 2.2.3 錯誤處理與恢復

- 當遇到 API 限流錯誤（429）時，將該 Key 標記為臨時不可用
- 實現指數退避算法，逐漸增加重試間隔
- 在一定時間後（如 1 小時）自動恢復 Key 的可用狀態

## 3. 安全存儲與保護

為防止 API Key 被提取或濫用，將採用多層保護策略：

### 3.1 分段存儲

- 將每個 API Key 分割成 3 個部分，分別存儲在不同位置
- 存儲位置包括：
  - 代碼常量（經過混淆）
  - 資源文件（經過加密）
  - 本地安全存儲（如 Keychain）

### 3.2 動態組合

- 運行時動態組合 API Key 的各個部分
- 使用設備特定信息作為組合因子，增加提取難度
- 組合邏輯：

```
function assembleApiKey(keyIndex) {
    let part1 = CODE_CONSTANTS[keyIndex]; // 從混淆代碼中獲取
    let part2 = decryptResource(RESOURCE_FILES[keyIndex]); // 從加密資源解密
    let part3 = secureStorage.get(KEY_IDENTIFIERS[keyIndex]); // 從安全存儲獲取
    
    // 使用設備特定信息進行組合
    let deviceFactor = generateDeviceFactor();
    return combineKeyParts(part1, part2, part3, deviceFactor);
}
```

### 3.3 代碼混淆與加密

- 使用高級代碼混淆技術處理包含 Key 部分的代碼
- 對存儲在資源文件中的 Key 部分進行加密
- 使用設備特定因素（如設備 ID、安裝 ID 等）作為加密密鑰

### 3.4 運行時保護

- 實現反調試機制，檢測可能的調試或逆向工程嘗試
- 在內存中最小化 API Key 的完整形式存在時間
- 使用後立即清除內存中的完整 Key

### 3.5 網絡安全

- 使用 HTTPS 進行所有 API 通信
- 實現證書固定（Certificate Pinning）防止中間人攻擊
- 在請求中添加設備指紋和時間戳，增加請求的唯一性

## 4. 客戶端限流機制

為防止單個用戶過度使用 API，實現嚴格的本地限流機制：

### 4.1 使用限制

- **每小時限制**：每個設備每小時最多 10 次深度分析請求
- **每日限制**：每個設備每天最多 30 次深度分析請求
- **連續使用限制**：連續 3 次請求後，強制間隔至少 5 分鐘

### 4.2 限流實現

- 使用本地安全存儲記錄 API 使用歷史
- 實現滑動窗口算法進行精確的時間限制
- 使用設備 ID 和安裝 ID 綁定使用記錄，防止重置限制

```
function canMakeApiRequest(analysisType) {
    let usageHistory = loadUsageHistory();
    
    // 檢查小時限制
    let hourlyRequests = countRequestsInLastHours(usageHistory, 1);
    if (hourlyRequests >= 10) {
        return {allowed: false, reason: "hourly_limit", nextAllowedTime: calculateNextAllowedTime(usageHistory, "hourly")};
    }
    
    // 檢查日限制
    let dailyRequests = countRequestsInLastHours(usageHistory, 24);
    if (dailyRequests >= 30) {
        return {allowed: false, reason: "daily_limit", nextAllowedTime: calculateNextAllowedTime(usageHistory, "daily")};
    }
    
    // 檢查連續使用限制
    let consecutiveRequests = countConsecutiveRequests(usageHistory);
    if (consecutiveRequests >= 3) {
        let lastRequestTime = getLastRequestTime(usageHistory);
        let currentTime = getCurrentTime();
        if (currentTime - lastRequestTime < 5 * 60 * 1000) { // 5分鐘
            return {allowed: false, reason: "consecutive_limit", nextAllowedTime: lastRequestTime + 5 * 60 * 1000};
        }
    }
    
    return {allowed: true};
}
```

### 4.3 用戶體驗優化

- 在 UI 中顯示剩餘可用分析次數
- 當接近限制時提供警告
- 當達到限制時，提供友好的解釋和下次可用時間
- 對於關鍵功能，保留少量"緊急配額"

### 4.4 優先級與降級

- 實現請求優先級系統：
  - 高優先級：用戶主動觸發的分析
  - 中優先級：定期自動分析
  - 低優先級：批量或後台分析
- 在接近限制時，優先保證高優先級請求
- 實現功能降級：當 API 不可用時，回退到本地分析

## 5. 智能緩存策略

通過智能緩存減少不必要的 API 調用：

### 5.1 結果緩存

- 緩存分析結果，有效期根據分析類型不同：
  - 睡眠模式分析：24 小時
  - 作息規律分析：12 小時
  - 預測結果：6 小時
- 當數據沒有顯著變化時，延長緩存有效期

### 5.2 增量分析

- 實現增量分析機制，只分析新增的數據
- 將新分析結果與緩存結果合併
- 使用數據變化檢測算法，判斷是否需要完整重新分析

### 5.3 預加載與批處理

- 在網絡和電量良好時預加載可能需要的分析
- 將多個小分析請求合併為批量請求
- 實現智能排程，在用戶不活躍時處理批量請求

### 5.4 緩存管理

- 實現 LRU (Least Recently Used) 緩存淘汰策略
- 定期清理過期緩存
- 在存儲空間不足時優先保留最重要的分析結果

## 6. 更新機制

為確保長期安全性，實現 API Key 的更新機制：

### 6.1 應用更新

- 主要通過應用更新推送新的 API Key
- 每次應用更新可更新部分或全部 Key
- 實現平滑過渡機制，確保更新過程中服務不中斷

### 6.2 遠程配置

- 設計（但暫不實現）從安全 CDN 獲取加密配置的機制
- 配置文件包含：
  - Key 部分的更新
  - 使用限制參數更新
  - 功能開關

### 6.3 版本控制

- 實現 API Key 版本控制機制
- 支持在一定時期內新舊 Key 共存
- 提供舊版本 Key 的優雅淘汰機制

## 7. 監控與分析

為持續優化 API 使用，實現本地監控機制：

### 7.1 使用統計

- 記錄 API 使用模式和頻率
- 分析不同功能的使用分佈
- 識別可能的優化機會

### 7.2 錯誤監控

- 記錄 API 調用錯誤和類型
- 實現自動錯誤恢復策略
- 在開發版本中提供詳細日誌

### 7.3 性能監控

- 記錄 API 響應時間
- 監控緩存命中率
- 分析電池和網絡消耗

## 8. 風險評估與緩解

### 8.1 已識別風險

| 風險 | 可能性 | 影響 | 緩解策略 |
|-----|-------|-----|---------|
| API Key 提取 | 中 | 高 | 分段存儲、代碼混淆、動態組合 |
| 單用戶過度使用 | 高 | 中 | 本地限流、使用監控、智能緩存 |
| 應用克隆/重打包 | 中 | 高 | 應用完整性檢查、設備綁定 |
| 中間人攻擊 | 低 | 高 | HTTPS、證書固定、請求簽名 |
| 逆向工程 | 中 | 高 | 代碼混淆、反調試、運行時保護 |

### 8.2 應急預案

- 檢測到異常使用模式時的自動限流
- 發現 Key 可能泄露時的快速更新機制
- 極端情況下的全局功能降級策略

## 9. 實施路線圖

API Key 管理策略的實施將分為以下階段：

### 9.1 第一階段：基礎實施

- 實現多 Key 存儲和基本輪換邏輯
- 實現基本的本地限流機制
- 實現簡單的結果緩存

### 9.2 第二階段：安全增強

- 實現分段存儲和動態組合
- 添加代碼混淆和加密保護
- 實現運行時保護機制

### 9.3 第三階段：優化與監控

- 實現高級緩存策略
- 添加使用統計和監控
- 優化負載均衡算法

### 9.4 第四階段：更新機制

- 實現 API Key 版本控制
- 設計遠程配置機制
- 完善應急預案

## 10. 結論

本文檔詳細描述了「寶寶生活記錄專業版」應用在純客戶端環境下的 API Key 管理與防濫用機制策略。通過多 Key 輪換、安全存儲、客戶端限流、智能緩存和更新機制的組合，可以有效保護 API Key 不被濫用或盜用，同時確保用戶能夠順暢地使用 AI 分析功能。

該策略平衡了安全性和用戶體驗，適合純客戶端環境的限制，並為未來可能的架構調整預留了擴展空間。
