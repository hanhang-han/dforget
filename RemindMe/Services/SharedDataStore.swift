// V1.1 — App Group 共享数据层
// 主 App 和 Widget Extension 通过共享 UserDefaults 同步最新提醒

import Foundation
import WidgetKit

struct SharedDataStore {
    static let shared = SharedDataStore()

    let defaults: UserDefaults

    private let suiteName = "group.com.hanhang.remindme"

    // Keys
    private let latestReminderKey = "shared_latest_reminder_text"
    private let latestReminderTimeKey = "shared_latest_reminder_time"
    private let latestReminderCategoryKey = "shared_latest_reminder_category"
    private let todayCountKey = "shared_today_count"
    private let allRemindersKey = "shared_all_reminders"

    /// 是否成功连接 App Group
    let isAvailable: Bool

    private init() {
        if let defaults = UserDefaults(suiteName: suiteName) {
            self.defaults = defaults
            self.isAvailable = true
        } else {
            // App Group 不可用时降级到标准 UserDefaults（仅主 App 可用，Widget 无法读取）
            self.defaults = .standard
            self.isAvailable = false
        }
    }

    // MARK: - 写入最新提醒

    func updateLatestReminder(text: String, category: String, timestamp: Date) {
        defaults.set(text, forKey: latestReminderKey)
        defaults.set(timestamp, forKey: latestReminderTimeKey)
        defaults.set(category, forKey: latestReminderCategoryKey)
    }

    func updateTodayCount(_ count: Int) {
        defaults.set(count, forKey: todayCountKey)
    }

    /// 写入最近的提醒列表（最多 10 条，供中等尺寸 Widget 使用）
    func updateReminderList(_ reminders: [(text: String, time: String, category: String)]) {
        let trimmed = Array(reminders.prefix(10))
        let data = trimmed.map { ["text": $0.text, "time": $0.time, "category": $0.category] }
        defaults.set(data, forKey: allRemindersKey)
    }

    // MARK: - 读取

    var latestReminderText: String? {
        defaults.string(forKey: latestReminderKey)
    }

    var latestReminderTime: String? {
        guard let date = defaults.object(forKey: latestReminderTimeKey) as? Date else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    var latestReminderCategory: String? {
        defaults.string(forKey: latestReminderCategoryKey)
    }

    var todayCount: Int {
        defaults.integer(forKey: todayCountKey)
    }

    var reminderList: [[String: String]] {
        defaults.array(forKey: allRemindersKey) as? [[String: String]] ?? []
    }

    // MARK: - 通知 Widget 刷新

    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
