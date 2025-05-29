import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("home", systemImage: "house.fill")
                }
                .tag(0)
            
            RecordView()
                .tabItem {
                    Label("record", systemImage: "square.and.pencil")
                }
                .tag(1)
            
            StatisticsView()
                .tabItem {
                    Label("statistics", systemImage: "chart.bar.fill")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .accentColor(Color("PrimaryColor"))
        .onAppear {
            // 設置TabBar外觀
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppSettings.shared)
            .environment(\.managedObjectContext, DataController.shared.container.viewContext)
    }
}
