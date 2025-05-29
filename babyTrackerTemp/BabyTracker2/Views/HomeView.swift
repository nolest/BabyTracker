import SwiftUI

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appSettings: AppSettings
    @State private var selectedBaby: Baby?
    @State private var babies: [Baby] = []
    @State private var recentActivities: [Activity] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 寶寶選擇器
                    if !babies.isEmpty {
                        BabySelectorView(babies: babies, selectedBaby: $selectedBaby)
                            .padding(.horizontal)
                    }
                    
                    // 寶寶狀態卡片
                    if let baby = selectedBaby {
                        BabyStatusCard(baby: baby)
                            .padding(.horizontal)
                    }
                    
                    // 快速操作
                    QuickActionsView(baby: selectedBaby)
                        .padding(.horizontal)
                    
                    // 最近活動
                    if !recentActivities.isEmpty {
                        RecentActivitiesView(activities: recentActivities)
                            .padding(.horizontal)
                    } else {
                        Text("No recent activities")
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("today".localized)
            .background(Color("BackgroundColor").edgesIgnoringSafeArea(.all))
            .onAppear(perform: loadData)
        }
    }
    
    private func loadData() {
        let dataController = DataController.shared
        babies = dataController.getAllBabies()
        
        // 如果有寶寶，選擇第一個
        if let firstBaby = babies.first, selectedBaby == nil {
            selectedBaby = firstBaby
            loadActivities()
        }
        
        // 如果沒有寶寶，創建一個示例寶寶（僅用於開發）
        if babies.isEmpty {
            let newBaby = dataController.addBaby(name: "Baby", birthDate: Date(), gender: "Male")
            babies = [newBaby]
            selectedBaby = newBaby
        }
    }
    
    private func loadActivities() {
        guard let baby = selectedBaby else { return }
        
        let dataController = DataController.shared
        recentActivities = dataController.getRecentActivities(for: baby)
    }
}

// BabySelectorView and BabyAvatarView are now defined in BabySelectorView.swift

struct BabyStatusCard: View {
    let baby: Baby
    @State private var lastFeeding: Activity?
    @State private var lastDiaper: Activity?
    @State private var lastSleep: Activity?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("baby_status".localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                StatusItemView(
                    title: "last_feeding".localized,
                    icon: "bottle.fill",
                    time: lastFeeding?.startTime,
                    color: Color("PrimaryColor")
                )
                
                StatusItemView(
                    title: "last_diaper".localized,
                    icon: "heart.fill",
                    time: lastDiaper?.startTime,
                    color: Color("SecondaryColor")
                )
                
                StatusItemView(
                    title: "last_sleep".localized,
                    icon: "moon.fill",
                    time: lastSleep?.startTime,
                    color: Color("AccentColor")
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onAppear(perform: loadLastActivities)
    }
    
    private func loadLastActivities() {
        let dataController = DataController.shared
        // 根據DataController的實際方法簽名調整參數
        lastFeeding = dataController.getRecentActivities(for: baby, limit: 1).first
        lastDiaper = dataController.getRecentActivities(for: baby, limit: 1).first
        lastSleep = dataController.getRecentActivities(for: baby, limit: 1).first
    }
}

struct StatusItemView: View {
    let title: String
    let icon: String
    let time: Date?
    let color: Color
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            if let time = time {
                Text(timeAgo(from: time))
                    .font(.caption2)
                    .foregroundColor(.gray)
            } else {
                Text("N/A")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day)d ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m ago"
        } else {
            return "Just now"
        }
    }
}

struct QuickActionsView: View {
    let baby: Baby?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("quick_actions".localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 15) {
                QuickActionButton(
                    title: "feeding".localized,
                    icon: "bottle.fill",
                    color: Color("PrimaryColor"),
                    action: {
                        // 導航到餵食記錄頁面
                    }
                )
                
                QuickActionButton(
                    title: "diaper".localized,
                    icon: "heart.fill",
                    color: Color("SecondaryColor"),
                    action: {
                        // 導航到尿布記錄頁面
                    }
                )
                
                QuickActionButton(
                    title: "sleep".localized,
                    icon: "moon.fill",
                    color: Color("AccentColor"),
                    action: {
                        // 導航到睡眠記錄頁面
                    }
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .clipShape(Circle())
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct RecentActivitiesView: View {
    let activities: [Activity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("recent_activities".localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(activities, id: \.id) { activity in
                ActivityRow(activity: activity)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ActivityRow: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: 15) {
            // 活動圖標
            Image(systemName: iconForActivity(activity))
                .font(.title3)
                .foregroundColor(colorForActivity(activity))
                .frame(width: 40, height: 40)
                .background(colorForActivity(activity).opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 5) {
                Text(titleForActivity(activity))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                if let startTime = activity.startTime {
                    Text(formatDate(startTime))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // 活動時長
            if activity.duration > 0 {
                Text(formatDuration(activity.duration))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func iconForActivity(_ activity: Activity) -> String {
        switch activity.type {
        case "feeding":
            return "bottle.fill"
        case "diaper":
            return "heart.fill"
        case "sleep":
            return "moon.fill"
        case "growth":
            return "ruler.fill"
        case "milestone":
            return "flag.fill"
        case "happy_moment":
            return "camera.fill"
        default:
            return "square.fill"
        }
    }
    
    private func colorForActivity(_ activity: Activity) -> Color {
        switch activity.type {
        case "feeding":
            return Color("PrimaryColor")
        case "diaper":
            return Color("SecondaryColor")
        case "sleep":
            return Color("AccentColor")
        case "growth":
            return Color.green
        case "milestone":
            return Color.orange
        case "happy_moment":
            return Color.purple
        default:
            return Color.gray
        }
    }
    
    private func titleForActivity(_ activity: Activity) -> String {
        switch activity.type {
        case "feeding":
            if let feedingActivity = activity as? FeedingActivity {
                return "\(feedingActivity.feedingType?.localized ?? "feeding".localized)"
            }
            return "feeding".localized
        case "diaper":
            if let diaperActivity = activity as? DiaperActivity {
                return "\(diaperActivity.diaperType?.localized ?? "diaper".localized)"
            }
            return "diaper".localized
        case "sleep":
            return "sleep".localized
        case "growth":
            return "growth".localized
        case "milestone":
            return "milestone".localized
        case "happy_moment":
            return "happy_moment".localized
        default:
            return activity.type?.localized ?? "custom".localized
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environment(\.managedObjectContext, DataController.shared.container.viewContext)
            .environmentObject(AppSettings.shared)
    }
}
