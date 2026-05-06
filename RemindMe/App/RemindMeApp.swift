import SwiftUI
import SwiftData

@main
struct RemindMeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ReminderItem.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupServices()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func setupServices() {
        // 检查通知权限状态
        NotificationService.shared.checkAuthorizationStatus()
        CalendarService.shared.checkAuthorizationStatus()

        // 启动定时推送（如果已完成引导）
        let prefs = UserPreferences.load()
        if prefs.hasCompletedOnboarding {
            NotificationService.shared.startPeriodicPush(
                intervalHours: prefs.pushFrequency,
                quietStart: prefs.quietTimeStart,
                quietEnd: prefs.quietTimeEnd,
                reminderProvider: {
                    let result = MockReminderEngine.shared.generateReminder()
                    return ("灵动提醒", result.text)
                }
            )
        }
    }
}
