// V1.1 — 通知服务 + Action Buttons
import UserNotifications
import SwiftUI

// 通知分类标识
let kReminderCategory = "REMINDER_CATEGORY"
let kActionPositive = "POSITIVE"
let kActionNegative = "NEGATIVE"

// MARK: - Notification Delegate（处理通知 Action 按钮）
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionId = response.actionIdentifier
        if actionId == kActionPositive || actionId == kActionNegative {
            Task { @MainActor in
                NotificationService.shared.handleNotificationAction(identifier: actionId)
            }
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false

    /// 防止递归推送链叠加
    private var periodicPushWorkItem: DispatchWorkItem?

    private init() {}

    /// 注册通知分类（含 action buttons）
    func registerCategories() {
        let positiveAction = UNNotificationAction(
            identifier: kActionPositive,
            title: "有用",
            options: []
        )
        let negativeAction = UNNotificationAction(
            identifier: kActionNegative,
            title: "不需要",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: kReminderCategory,
            actions: [positiveAction, negativeAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    self.registerCategories()
                }
                completion?(granted)
            }
        }
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func scheduleNotification(
        title: String,
        body: String,
        after interval: TimeInterval = 0,
        identifier: String = UUID().uuidString
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = kReminderCategory

        // 应用用户音效设置
        let prefs = UserPreferences.load()
        switch prefs.soundType {
        case .gentle, .urgent:
            content.sound = .default
        case .silent:
            content.sound = nil
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(interval, 1), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    /// 启动模拟推送 Timer，每 2~3 小时推送一次
    func startPeriodicPush(
        intervalHours: Int,
        quietStart: String,
        quietEnd: String,
        reminderProvider: @escaping () -> (String, String)
    ) {
        // 取消旧的递归链，防止叠加
        periodicPushWorkItem?.cancel()

        let intervalSeconds = TimeInterval(intervalHours) * 3600
        let jitter = TimeInterval.random(in: 0...3600)

        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }

            if !self.isInQuietPeriod(start: quietStart, end: quietEnd) {
                let (title, body) = reminderProvider()
                self.scheduleNotification(title: title, body: body)
            }

            self.startPeriodicPush(
                intervalHours: intervalHours,
                quietStart: quietStart,
                quietEnd: quietEnd,
                reminderProvider: reminderProvider
            )
        }
        periodicPushWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + intervalSeconds + jitter, execute: item)
    }

    /// 处理通知 action 反馈
    func handleNotificationAction(identifier: String) {
        let learner = PreferenceLearner.shared
        switch identifier {
        case kActionPositive:
            learner.processFeedback("positive")
        case kActionNegative:
            learner.processFeedback("negative")
        default:
            break
        }
    }

    private func isInQuietPeriod(start: String, end: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        guard let startTime = formatter.date(from: start),
              let endTime = formatter.date(from: end) else { return false }

        let now = Date()
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.hour, .minute], from: now)
        let currentMinutes = (currentComponents.hour ?? 0) * 60 + (currentComponents.minute ?? 0)

        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)

        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)

        if startMinutes > endMinutes {
            return currentMinutes >= startMinutes || currentMinutes < endMinutes
        } else {
            return currentMinutes >= startMinutes && currentMinutes < endMinutes
        }
    }
}
