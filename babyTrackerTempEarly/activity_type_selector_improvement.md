# 寶寶生活記錄專業版（Baby Tracker）- 活動類型選擇器改進

## 1. 問題描述

在整合驗證過程中，發現活動類型選擇器在某些iOS版本上顯示不正確，可能導致以下問題：

1. 用戶界面不一致，影響用戶體驗
2. 選擇器在某些iOS版本上顯示異常或功能失效
3. 缺少活動類型的國際化支持
4. 視覺設計與應用整體風格不匹配
5. 可訪問性支持不足，不利於特殊需求用戶使用

## 2. 修正方案

### 2.1 創建統一的活動類型選擇器

首先，創建一個統一的活動類型選擇器組件，確保在所有iOS版本上顯示一致：

```swift
// ActivityTypeSelector.swift

struct ActivityTypeSelector: View {
    @Binding var selectedType: ActivityType
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題
            HStack {
                Text("選擇活動類型")
                    .font(.headline)
                    .padding()
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            
            // 分隔線
            Divider()
            
            // 活動類型列表
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(ActivityType.allCases, id: \.self) { type in
                        ActivityTypeRow(
                            type: type,
                            isSelected: selectedType == type,
                            onSelect: {
                                selectedType = type
                                presentationMode.wrappedValue.dismiss()
                            }
                        )
                        
                        if type != ActivityType.allCases.last {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

// 活動類型行
struct ActivityTypeRow: View {
    let type: ActivityType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // 圖標
                ZStack {
                    Circle()
                        .fill(typeColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: typeIconName)
                        .foregroundColor(typeColor)
                        .font(.system(size: 18))
                }
                
                // 標題
                VStack(alignment: .leading, spacing: 4) {
                    Text(typeLocalizedName)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(typeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 選中標記
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
    }
    
    // 活動類型圖標
    private var typeIconName: String {
        switch type {
        case .sleep:
            return "bed.double.fill"
        case .feeding:
            return "bottle.fill"
        case .diaper:
            return "heart.fill"
        case .growth:
            return "ruler.fill"
        case .milestone:
            return "star.fill"
        case .activity:
            return "figure.walk"
        case .medication:
            return "pills.fill"
        case .temperature:
            return "thermometer"
        case .bath:
            return "drop.fill"
        case .playtime:
            return "gamecontroller.fill"
        case .tummyTime:
            return "figure.roll"
        case .outdoors:
            return "sun.max.fill"
        case .other:
            return "ellipsis.circle.fill"
        }
    }
    
    // 活動類型顏色
    private var typeColor: Color {
        switch type {
        case .sleep:
            return .indigo
        case .feeding:
            return .orange
        case .diaper:
            return .green
        case .growth:
            return .blue
        case .milestone:
            return .yellow
        case .activity:
            return .purple
        case .medication:
            return .red
        case .temperature:
            return .pink
        case .bath:
            return .cyan
        case .playtime:
            return .mint
        case .tummyTime:
            return .teal
        case .outdoors:
            return .brown
        case .other:
            return .gray
        }
    }
    
    // 活動類型本地化名稱
    private var typeLocalizedName: String {
        switch type {
        case .sleep:
            return NSLocalizedString("睡眠", comment: "Sleep activity type")
        case .feeding:
            return NSLocalizedString("餵食", comment: "Feeding activity type")
        case .diaper:
            return NSLocalizedString("換尿布", comment: "Diaper activity type")
        case .growth:
            return NSLocalizedString("成長記錄", comment: "Growth activity type")
        case .milestone:
            return NSLocalizedString("里程碑", comment: "Milestone activity type")
        case .activity:
            return NSLocalizedString("活動", comment: "Activity type")
        case .medication:
            return NSLocalizedString("用藥", comment: "Medication activity type")
        case .temperature:
            return NSLocalizedString("體溫", comment: "Temperature activity type")
        case .bath:
            return NSLocalizedString("洗澡", comment: "Bath activity type")
        case .playtime:
            return NSLocalizedString("遊戲時間", comment: "Playtime activity type")
        case .tummyTime:
            return NSLocalizedString("趴睡時間", comment: "Tummy time activity type")
        case .outdoors:
            return NSLocalizedString("戶外活動", comment: "Outdoors activity type")
        case .other:
            return NSLocalizedString("其他", comment: "Other activity type")
        }
    }
    
    // 活動類型描述
    private var typeDescription: String {
        switch type {
        case .sleep:
            return NSLocalizedString("記錄寶寶的睡眠時間和質量", comment: "Sleep activity description")
        case .feeding:
            return NSLocalizedString("記錄餵食類型、時間和數量", comment: "Feeding activity description")
        case .diaper:
            return NSLocalizedString("記錄尿布更換情況", comment: "Diaper activity description")
        case .growth:
            return NSLocalizedString("記錄身高、體重和頭圍", comment: "Growth activity description")
        case .milestone:
            return NSLocalizedString("記錄寶寶的重要發展里程碑", comment: "Milestone activity description")
        case .activity:
            return NSLocalizedString("記錄寶寶的日常活動", comment: "Activity description")
        case .medication:
            return NSLocalizedString("記錄用藥情況和劑量", comment: "Medication activity description")
        case .temperature:
            return NSLocalizedString("記錄寶寶的體溫", comment: "Temperature activity description")
        case .bath:
            return NSLocalizedString("記錄洗澡時間和情況", comment: "Bath activity description")
        case .playtime:
            return NSLocalizedString("記錄遊戲時間和活動", comment: "Playtime activity description")
        case .tummyTime:
            return NSLocalizedString("記錄寶寶的趴睡時間", comment: "Tummy time activity description")
        case .outdoors:
            return NSLocalizedString("記錄戶外活動時間和類型", comment: "Outdoors activity description")
        case .other:
            return NSLocalizedString("記錄其他類型的活動", comment: "Other activity description")
        }
    }
}

// 活動類型枚舉
enum ActivityType: String, CaseIterable {
    case sleep = "sleep"
    case feeding = "feeding"
    case diaper = "diaper"
    case growth = "growth"
    case milestone = "milestone"
    case activity = "activity"
    case medication = "medication"
    case temperature = "temperature"
    case bath = "bath"
    case playtime = "playtime"
    case tummyTime = "tummyTime"
    case outdoors = "outdoors"
    case other = "other"
}
```

### 2.2 創建活動類型選擇器修飾器

創建一個修飾器，方便在任何視圖中使用活動類型選擇器：

```swift
// ActivityTypeSelectorModifier.swift

struct ActivityTypeSelectorModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var selectedType: ActivityType
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                ActivityTypeSelector(selectedType: $selectedType)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
    }
}

// 擴展 View 以方便使用活動類型選擇器修飾器
extension View {
    func activityTypeSelector(isPresented: Binding<Bool>, selectedType: Binding<ActivityType>) -> some View {
        self.modifier(ActivityTypeSelectorModifier(isPresented: isPresented, selectedType: selectedType))
    }
}
```

### 2.3 創建活動類型選擇按鈕

創建一個統一的活動類型選擇按鈕，用於觸發活動類型選擇器：

```swift
// ActivityTypeButton.swift

struct ActivityTypeButton: View {
    let type: ActivityType
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // 圖標
                ZStack {
                    Circle()
                        .fill(typeColor.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: typeIconName)
                        .foregroundColor(typeColor)
                        .font(.system(size: 16))
                }
                
                // 標題
                Text(typeLocalizedName)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 箭頭
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 活動類型圖標
    private var typeIconName: String {
        // 與 ActivityTypeRow 相同的實現
        switch type {
        case .sleep:
            return "bed.double.fill"
        case .feeding:
            return "bottle.fill"
        case .diaper:
            return "heart.fill"
        case .growth:
            return "ruler.fill"
        case .milestone:
            return "star.fill"
        case .activity:
            return "figure.walk"
        case .medication:
            return "pills.fill"
        case .temperature:
            return "thermometer"
        case .bath:
            return "drop.fill"
        case .playtime:
            return "gamecontroller.fill"
        case .tummyTime:
            return "figure.roll"
        case .outdoors:
            return "sun.max.fill"
        case .other:
            return "ellipsis.circle.fill"
        }
    }
    
    // 活動類型顏色
    private var typeColor: Color {
        // 與 ActivityTypeRow 相同的實現
        switch type {
        case .sleep:
            return .indigo
        case .feeding:
            return .orange
        case .diaper:
            return .green
        case .growth:
            return .blue
        case .milestone:
            return .yellow
        case .activity:
            return .purple
        case .medication:
            return .red
        case .temperature:
            return .pink
        case .bath:
            return .cyan
        case .playtime:
            return .mint
        case .tummyTime:
            return .teal
        case .outdoors:
            return .brown
        case .other:
            return .gray
        }
    }
    
    // 活動類型本地化名稱
    private var typeLocalizedName: String {
        // 與 ActivityTypeRow 相同的實現
        switch type {
        case .sleep:
            return NSLocalizedString("睡眠", comment: "Sleep activity type")
        case .feeding:
            return NSLocalizedString("餵食", comment: "Feeding activity type")
        case .diaper:
            return NSLocalizedString("換尿布", comment: "Diaper activity type")
        case .growth:
            return NSLocalizedString("成長記錄", comment: "Growth activity type")
        case .milestone:
            return NSLocalizedString("里程碑", comment: "Milestone activity type")
        case .activity:
            return NSLocalizedString("活動", comment: "Activity type")
        case .medication:
            return NSLocalizedString("用藥", comment: "Medication activity type")
        case .temperature:
            return NSLocalizedString("體溫", comment: "Temperature activity type")
        case .bath:
            return NSLocalizedString("洗澡", comment: "Bath activity type")
        case .playtime:
            return NSLocalizedString("遊戲時間", comment: "Playtime activity type")
        case .tummyTime:
            return NSLocalizedString("趴睡時間", comment: "Tummy time activity type")
        case .outdoors:
            return NSLocalizedString("戶外活動", comment: "Outdoors activity type")
        case .other:
            return NSLocalizedString("其他", comment: "Other activity type")
        }
    }
}
```

### 2.4 添加國際化支持

為活動類型添加國際化支持，創建 Localizable.strings 文件：

```swift
// Localizable.strings (繁體中文)

/* Sleep activity type */
"睡眠" = "睡眠";

/* Feeding activity type */
"餵食" = "餵食";

/* Diaper activity type */
"換尿布" = "換尿布";

/* Growth activity type */
"成長記錄" = "成長記錄";

/* Milestone activity type */
"里程碑" = "里程碑";

/* Activity type */
"活動" = "活動";

/* Medication activity type */
"用藥" = "用藥";

/* Temperature activity type */
"體溫" = "體溫";

/* Bath activity type */
"洗澡" = "洗澡";

/* Playtime activity type */
"遊戲時間" = "遊戲時間";

/* Tummy time activity type */
"趴睡時間" = "趴睡時間";

/* Outdoors activity type */
"戶外活動" = "戶外活動";

/* Other activity type */
"其他" = "其他";

/* Sleep activity description */
"記錄寶寶的睡眠時間和質量" = "記錄寶寶的睡眠時間和質量";

/* Feeding activity description */
"記錄餵食類型、時間和數量" = "記錄餵食類型、時間和數量";

/* Diaper activity description */
"記錄尿布更換情況" = "記錄尿布更換情況";

/* Growth activity description */
"記錄身高、體重和頭圍" = "記錄身高、體重和頭圍";

/* Milestone activity description */
"記錄寶寶的重要發展里程碑" = "記錄寶寶的重要發展里程碑";

/* Activity description */
"記錄寶寶的日常活動" = "記錄寶寶的日常活動";

/* Medication activity description */
"記錄用藥情況和劑量" = "記錄用藥情況和劑量";

/* Temperature activity description */
"記錄寶寶的體溫" = "記錄寶寶的體溫";

/* Bath activity description */
"記錄洗澡時間和情況" = "記錄洗澡時間和情況";

/* Playtime activity description */
"記錄遊戲時間和活動" = "記錄遊戲時間和活動";

/* Tummy time activity description */
"記錄寶寶的趴睡時間" = "記錄寶寶的趴睡時間";

/* Outdoors activity description */
"記錄戶外活動時間和類型" = "記錄戶外活動時間和類型";

/* Other activity description */
"記錄其他類型的活動" = "記錄其他類型的活動";
```

```swift
// Localizable.strings (English)

/* Sleep activity type */
"睡眠" = "Sleep";

/* Feeding activity type */
"餵食" = "Feeding";

/* Diaper activity type */
"換尿布" = "Diaper";

/* Growth activity type */
"成長記錄" = "Growth";

/* Milestone activity type */
"里程碑" = "Milestone";

/* Activity type */
"活動" = "Activity";

/* Medication activity type */
"用藥" = "Medication";

/* Temperature activity type */
"體溫" = "Temperature";

/* Bath activity type */
"洗澡" =
(Content truncated due to size limit. Use line ranges to read in chunks)