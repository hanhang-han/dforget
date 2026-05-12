import SwiftUI
import SwiftData
import UIKit
import UserNotifications

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

    init() {
        // UIKit appearance: dark navigation bars
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupServices()
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    BackgroundRotationService.shared.scheduleNextRefresh()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    let store = SharedDataStore.shared
                    if let text = store.latestReminderText {
                        Task {
                            await LiveActivityService.shared.updateLiveActivity(reminderText: text)
                        }
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func setupServices() {
        BackgroundRotationService.shared.register()
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        NotificationService.shared.checkAuthorizationStatus()
        CalendarService.shared.checkAuthorizationStatus()

        let prefs = UserPreferences.load()
        if prefs.hasCompletedOnboarding {
            NotificationService.shared.startPeriodicPush(
                intervalHours: prefs.pushFrequency,
                quietStart: prefs.quietTimeStart,
                quietEnd: prefs.quietTimeEnd,
                reminderProvider: {
                    let result = ContextEngine.shared.generate()
                    return ("灵动提醒", result.text)
                }
            )

            let result = ContextEngine.shared.generate()
            Task {
                await LiveActivityService.shared.updateLiveActivity(reminderText: result.text)
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "remindme" else { return }

        switch url.host {
        case "refresh":
            // 灵动岛"换一个" = 隐式负面信号
            PreferenceLearner.shared.processRefresh()
            let store = SharedDataStore.shared
            if let category = store.latestReminderCategory {
                PreferenceLearner.shared.recordCategoryImplicit(category: category, positive: false)
            }
            // 生成新提醒
            let result = ContextEngine.shared.generate()
            Task {
                await LiveActivityService.shared.updateLiveActivity(reminderText: result.text)
            }
        case "dismiss":
            LiveActivityService.shared.endLiveActivity()
        default:
            break
        }
    }
}
