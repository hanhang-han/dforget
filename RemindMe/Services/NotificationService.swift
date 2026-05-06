import UserNotifications
import SwiftUI

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false

    private init() {}

    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
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
        content.sound = .default

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
        // TODO: AI Integration — 根据用户偏好和上下文生成个性化提醒内容
        let intervalSeconds = TimeInterval(intervalHours) * 3600
        // 添加随机偏移 0~1 小时，模拟 2~3 小时间隔
        let jitter = TimeInterval.random(in: 0...3600)

        DispatchQueue.main.asyncAfter(deadline: .now() + intervalSeconds + jitter) { [weak self] in
            guard let self else { return }

            // 检查安静时段
            if !self.isInQuietPeriod(start: quietStart, end: quietEnd) {
                let (title, body) = reminderProvider()
                self.scheduleNotification(title: title, body: body)
            }

            // 递归调度下一次
            self.startPeriodicPush(
                intervalHours: intervalHours,
                quietStart: quietStart,
                quietEnd: quietEnd,
                reminderProvider: reminderProvider
            )
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

        // 跨午夜的情况 (如 23:00 ~ 08:00)
        if startMinutes > endMinutes {
            return currentMinutes >= startMinutes || currentMinutes < endMinutes
        } else {
            return currentMinutes >= startMinutes && currentMinutes < endMinutes
        }
    }
}
