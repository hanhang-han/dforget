import Foundation
import SwiftUI
import SwiftData

@MainActor
final class ReminderFeedViewModel: ObservableObject {
    @Published var reminders: [ReminderItem] = []
    @Published var isLoading = false

    private let mockEngine = MockReminderEngine.shared
    private let liveActivityService = LiveActivityService.shared
    private let notificationService = NotificationService.shared

    private var modelContext: ModelContext?

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchReminders()
    }

    func fetchReminders() {
        guard let modelContext else { return }

        let descriptor = FetchDescriptor<ReminderItem>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            reminders = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch reminders: \(error)")
        }
    }

    /// 生成一条新提醒并保存
    func generateNewReminder() {
        guard let modelContext else { return }

        let result = mockEngine.generateReminder()
        let item = ReminderItem(
            text: result.text,
            category: result.category,
            timestamp: .now,
            isRead: false,
            isSmallNote: result.isSmallNote
        )

        modelContext.insert(item)

        do {
            try modelContext.save()
            fetchReminders()
            updateLiveActivity(with: item)
        } catch {
            print("Failed to save reminder: \(error)")
        }
    }

    /// 生成一天的模拟提醒
    func generateDailyReminders() {
        guard let modelContext else { return }

        let results = mockEngine.generateDailyReminders()

        for (index, result) in results.enumerated() {
            // 将时间分散在当天内
            let hour = 8 + index * 3
            let components = DateComponents(hour: min(hour, 21), minute: Int.random(in: 0...59))
            let timestamp = Calendar.current.date(from: components) ?? .now

            let item = ReminderItem(
                text: result.text,
                category: result.category,
                timestamp: timestamp,
                isRead: false,
                isSmallNote: result.isSmallNote
            )
            modelContext.insert(item)
        }

        do {
            try modelContext.save()
            fetchReminders()

            // 用最新的提醒更新灵动岛
            if let latest = reminders.first {
                updateLiveActivity(with: latest)
            }
        } catch {
            print("Failed to save daily reminders: \(error)")
        }
    }

    /// 标记为已读
    func markAsRead(_ item: ReminderItem) {
        item.isRead = true
        saveContext()
    }

    /// 删除提醒
    func deleteReminder(_ item: ReminderItem) {
        guard let modelContext else { return }
        modelContext.delete(item)
        saveContext()
        fetchReminders()
    }

    /// 设置反馈类型
    func setFeedback(_ item: ReminderItem, type: String) {
        item.feedbackType = type
        saveContext()

        // V1.1: 通过 PreferenceLearner 学习用户偏好
        let learner = PreferenceLearner.shared
        learner.processFeedback(type)
        learner.recordCategoryFeedback(
            category: item.category.displayName,
            positive: type == "positive" || type == "thumbUp"
        )
        learner.recordActiveHour(Calendar.current.component(.hour, from: .now))
    }

    // MARK: - Private

    private func updateLiveActivity(with item: ReminderItem) {
        liveActivityService.updateLiveActivity(reminderText: item.text)
    }

    private func saveContext() {
        guard let modelContext else { return }
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}
