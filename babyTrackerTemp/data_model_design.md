# 寶寶生活記錄專業版（Baby Tracker）- 第一階段：數據模型設計

## Core Data 數據模型

本應用使用 Core Data 作為本地數據存儲解決方案。以下是主要實體及其關係的詳細設計。

### 主要實體

#### 1. Baby（寶寶）

```swift
// Baby 實體
entity Baby {
    // 基本屬性
    attribute id: UUID, required, indexed
    attribute name: String, required
    attribute birthDate: Date, required
    attribute gender: String // "male", "female", "other"
    attribute photoData: Binary, optional
    attribute createdAt: Date, required
    attribute updatedAt: Date, required
    
    // 發展階段相關
    attribute developmentStage: String, optional // 例如："newborn", "infant", "toddler"
    attribute notes: String, optional
    
    // 關係
    relationship sleepRecords: to-many SleepRecord, inverse: baby, delete-rule: cascade
    relationship activities: to-many Activity, inverse: baby, delete-rule: cascade
    relationship feedingRecords: to-many FeedingRecord, inverse: baby, delete-rule: cascade
    relationship diaperRecords: to-many DiaperRecord, inverse: baby, delete-rule: cascade
    relationship growthRecords: to-many GrowthRecord, inverse: baby, delete-rule: cascade
    relationship analyses: to-many Analysis, inverse: baby, delete-rule: cascade
    relationship familyMembers: to-many FamilyMember, inverse: babies, delete-rule: nullify
}
```

#### 2. SleepRecord（睡眠記錄）

```swift
// SleepRecord 實體
entity SleepRecord {
    // 基本屬性
    attribute id: UUID, required, indexed
    attribute startTime: Date, required
    attribute endTime: Date, optional // 可能尚未結束
    attribute duration: Double, optional // 以分鐘為單位
    attribute quality: Integer16, optional // 1-5 評分
    attribute notes: String, optional
    attribute createdAt: Date, required
    attribute updatedAt: Date, required
    
    // 中斷相關
    attribute interruptionCount: Integer16, default: 0
    attribute totalInterruptionTime: Double, default: 0 // 以分鐘為單位
    
    // 關係
    relationship baby: to-one Baby, inverse: sleepRecords, required
    relationship environmentFactors: to-many EnvironmentFactor, inverse: sleepRecord, delete-rule: cascade
    relationship sleepInterruptions: to-many SleepInterruption, inverse: sleepRecord, delete-rule: cascade
}
```

#### 3. EnvironmentFactor（環境因素）

```swift
// EnvironmentFactor 實體
entity EnvironmentFactor {
    // 基本屬性
    attribute id: UUID, required, indexed
    attribute type: String, required // "light", "noise", "temperature"
    attribute value: String, required // 例如 light: "bright", "dim", "dark"
    attribute timestamp: Date, required
    
    // 關係
    relationship sleepRecord: to-one SleepRecord, inverse: environmentFactors, required
}
```

#### 4. SleepInterruption（睡眠中斷）

```swift
// SleepInterruption 實體
entity SleepInterruption {
    // 基本屬性
    attribute id: UUID, required, indexed
    attribute startTime: Date, required
    attribute endTime: Date, required
    attribute duration: Double, required // 以分鐘為單位
    attribute reason: String, optional // 中斷原因
    
    // 關係
    relationship sleepRecord: to-one SleepRecord, inverse: sleepInterruptions, required
}
```

#### 5. Activity（活動）

```swift
// Activity 實體
entity Activity {
    // 基本屬性
    attribute id: UUID, required, indexed
    attribute type: String, required // "feeding", "diaper", "bath", "play", "custom"
    attribute startTime: Date, required
    attribute endTime: Date, optional
    attribute duration: Double, optional // 以分鐘為單位
    attribute notes: String, optional
    attribute createdAt: Date, required
    attribute updatedAt: Date, required
    
    // 自定義活動相關
    attribute customType: String, optional // 自定義活動類型
    
    // 關係
    relationship baby: to-one Baby, inverse: activities, required
}
```

#### 6. FeedingRecord（餵食記錄）

```swift
// FeedingRecord 實體
entity FeedingRecord {
    // 基本屬性
    attribute id: UUID, required, indexed
    attribute type: String, required // "breast", "bottle", "formula", "solid"
    attribute startTime: Date, required
    attribute endTime: Date, optional
    attribute duration: Double, optional // 以分鐘為單位，用於母乳餵食
    attribute amount: Double, optional // 以毫升為單位，用於奶瓶餵食
    attribute notes: String, optional
    attribute createdAt: Date, required
    attribute updatedAt: Date, required
    
    // 母乳餵食相關
    attribute breastSide: String, optional // "left", "right", "both"
    
    // 固體食物相關
    attribute foodType: String, optional // 食物類型
    
    // 關係
    relationship baby: to-one Baby, inverse: feedingRecords, required
}
```

#### 7. DiaperRecord（尿布記錄）

```swift
// DiaperRecord 實體
entity DiaperRecord {
    // 基本屬性
    attribute id: UUID, required, indexed
    attribute time: Date, required
    attribute type: String, required // "wet", "dirty", "mixed", "dry"
    attribute notes: String, optional
    attribute createdAt: Date, required
    attribute updatedAt: Date, required
    
    // 關係
    relationship baby: to-one Baby, inverse: diaperRecords, required
}
```

#### 8. GrowthRecord（成長記錄）

```swift
// GrowthRecord 實體
entity GrowthRecord {
    // 基本屬性
    attribute id: UUID, required, indexed
    attribute date: Date, required
    attribute height: Double, optional // 以厘米為單位
    attribute weight: Double, optional // 以公斤為單位
    attribute headCircumference: Double, optional // 以厘米為單位
    attribute notes: String, optional
    attribute createdAt: Date, required
    attribute updatedAt: Date, required
    
    // 關係
    relationship baby: to-one Baby, inverse: growthRecords, required
}
```

#### 9. Analysis（分析結果）

```swift
// Analysis 實體
entity Analysis {
    // 基本屬性
    attribute id: UUID, required, indexed
    attribute type: String, required // "sleep_pattern", "feeding_pattern", "growth_trend"
    attribute result: Binary, required // 序列化的分析結果
    attribute creationDate: Date, required
    attribute validUntil: Date, optional // 結果有效期
    attribute summary: String, optional // 分析摘要
    
    // 關係
    relationship baby: to-one Baby, inverse: analyses, required
    relationship recommendations: to-many Recommendation, inverse: analysis, delete-rule: cascade
}
```

#### 10. Recommendation（建議）

```swift
// Recommendation 實體
entity Recommendation {
    // 基本屬性
    attribute id: UUID, required, indexed
    attribute content: String, required // 建議內容
    attribute basis: String, required // 建議依據
    attribute creationDate: Date, required
    attribute status: String, default: "new" // "new", "viewed", "applied", "ignored"
    attribute effectiveness: Integer16, optional // 用戶評分 1-5
    attribute userFeedback: String, optional // 用戶反饋
    
    // 關係
    relationship analysis: to-one Analysis, inverse: recommendations, required
}
```

#### 11. FamilyMember（家庭成員）

```swift
// FamilyMember 實體
entity FamilyMember {
    // 基本屬性
    attribute id: UUID, required, indexed
    attribute name: String, required
    attribute role: String, required // "parent", "grandparent", "sibling", "caregiver"
    attribute email: String, optional
    attribute createdAt: Date, required
    attribute updatedAt: Date, required
    
    // 權限相關
    attribute permissionLevel: String, default: "view" // "view", "edit", "admin"
    
    // 關係
    relationship babies: to-many Baby, inverse: familyMembers
}
```

## 數據模型關係圖

```
+-------------+       +---------------+       +-------------------+
|    Baby     |<----->| SleepRecord   |<----->| EnvironmentFactor |
+-------------+       +---------------+       +-------------------+
      ^                     ^
      |                     |
      v                     v
+-------------+       +-------------------+
| Activity    |       | SleepInterruption |
+-------------+       +-------------------+
      ^
      |
      v
+-------------+       +---------------+       +----------------+
| FeedingRecord|<----->|  DiaperRecord |<----->| GrowthRecord   |
+-------------+       +---------------+       +----------------+
                                                      ^
                                                      |
                                                      v
+-------------+       +---------------+       +----------------+
| Analysis    |<----->| Recommendation|<----->| FamilyMember   |
+-------------+       +---------------+       +----------------+
```

## 數據模型設計考量

1. **擴展性**：
   - 設計支持未來添加新的記錄類型和分析功能
   - 使用通用的 Activity 實體支持自定義活動類型

2. **數據完整性**：
   - 使用必要屬性和關係確保數據完整性
   - 設置適當的刪除規則（cascade, nullify）管理實體間的依賴關係

3. **查詢效率**：
   - 為常用查詢條件（如 id, date）添加索引
   - 設計適當的關係，避免複雜的多表查詢

4. **數據遷移**：
   - 考慮未來版本更新時的數據模型遷移
   - 使用版本化的數據模型（.xcdatamodeld）

5. **隱私與安全**：
   - 所有敏感數據僅存儲在本地或通過安全通道同步
   - 實現細粒度的訪問控制，特別是對於家庭共享功能

## 第一階段實現範圍

在第一階段，我們將優先實現以下實體：

1. Baby
2. SleepRecord
3. EnvironmentFactor
4. SleepInterruption

其他實體將在後續階段根據需要實現。
