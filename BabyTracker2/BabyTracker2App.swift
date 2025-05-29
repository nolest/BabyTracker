import SwiftUI

@main
struct BabyTracker2App: App {
    @StateObject private var dataController = DataController.shared
    @StateObject private var appSettings = AppSettings.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(appSettings)
                .onAppear {
                    // 設置初始語言
                    LocalizationService.shared.setLanguage(appSettings.language)
                }
        }
    }
}
