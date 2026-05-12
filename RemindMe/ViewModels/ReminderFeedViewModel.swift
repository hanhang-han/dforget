import Foundation
import SwiftUI
import SwiftData

@MainActor
final class ReminderFeedViewModel: ObservableObject {
    @Published var currentText: String = ""
    @Published var currentCategory: ReminderCategory = .general
    @Published var currentIsSmallNote: Bool = false
    @Published var reminders: [ReminderItem] = []
    @Published var lastRotationTime: Date = .now

    /// 今天已展示过的场景 ID（用于去重）
    private var seenToday: Set<String> = []
    private var lastRotationDate: String = ""   // 用于跨天清空 seenToday
    private var isInitialized = false

    private let contextEngine = ContextEngine.shared
    private let liveActivityService = LiveActivityService.shared
    private var rotationTimer: Timer?
    private var modelContext: ModelContext?

    // MARK: - 生命周期

    func start(modelContext: ModelContext) {
        self.modelContext = modelContext

        if isInitialized {
            startTimer()
            return
        }
        isInitialized = true

        UIDevice.current.isBatteryMonitoringEnabled = true
        cleanupOldReminders()
        rotateToNext()
        ensureLiveActivity()
        startTimer()

        // 隐式信号：用户打开 App = 被当前内容吸引
        if hasContent {
            PreferenceLearner.shared.processAppOpen()
            PreferenceLearner.shared.recordCategoryImplicit(
                category: currentCategory.displayName, positive: true
            )
        }
    }

    func stop() {
        rotationTimer?.invalidate()
        rotationTimer = nil
    }

    // MARK: - 轮换

    private func startTimer() {
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.rotateToNext()
            }
        }
    }

    func rotateToNext() {
        checkDayRollover()

        // 检查当前时段是否启用
        let prefs = UserPreferences.load()
        if !isCurrentTimeSlotEnabled(prefs.timeSlotToggles) {
            return
        }

        // 检查今日上限
        let today = Calendar.current.startOfDay(for: .now)
        let todayCount = reminders.filter { $0.timestamp >= today }.count
        if todayCount >= prefs.dailyLimit {
            return
        }

        let battery = UIDevice.current.batteryLevel >= 0 ? UIDevice.current.batteryLevel : nil
        let result = contextEngine.rotate(seenToday: seenToday, batteryLevel: battery)

        if let sceneId = result.sceneId {
            seenToday.insert(sceneId)
        }

        // 更新展示数据
        currentText = result.text
        currentCategory = result.category
        currentIsSmallNote = result.isSmallNote
        lastRotationTime = .now

        // 存入 SwiftData（静默归档）
        saveReminder(result)

        // 同步灵动岛 + Widget
        Task {
            await liveActivityService.updateLiveActivity(reminderText: result.text)
        }
        syncToSharedStore()
    }

    /// 是否为当前展示的提醒
    var hasContent: Bool {
        !currentText.isEmpty
    }

    // MARK: - 反馈

    func setFeedback(type: String) {
        let learner = PreferenceLearner.shared
        learner.processFeedback(type)
        learner.recordCategoryFeedback(
            category: currentCategory.displayName,
            positive: type == "positive" || type == "thumbUp"
        )
        learner.recordActiveHour(Calendar.current.component(.hour, from: .now))

        // 反馈后立即轮换到下一条
        rotateToNext()
    }

    // MARK: - Private

    private func checkDayRollover() {
        let today = DateFormatter.localizedString(from: .now, dateStyle: .short, timeStyle: .none)
        if today != lastRotationDate {
            seenToday.removeAll()
            lastRotationDate = today
        }
    }

    private func saveReminder(_ result: FusedReminder) {
        guard let modelContext else { return }
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
        } catch {
            print("Failed to save reminder: \(error)")
        }
    }

    private func fetchReminders() {
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

    private func ensureLiveActivity() {
        if liveActivityService.currentActivity == nil {
            liveActivityService.startLiveActivity(reminderText: currentText)
        }
    }

    private func syncToSharedStore() {
        let store = SharedDataStore.shared
        store.updateLatestReminder(
            text: currentText,
            category: currentCategory.displayName,
            timestamp: Date()
        )
        let today = Calendar.current.startOfDay(for: .now)
        let todayCount = reminders.filter { $0.timestamp >= today }.count
        store.updateTodayCount(todayCount)
        store.reloadWidgets()
    }

    /// 检查当前时段是否启用
    private func isCurrentTimeSlotEnabled(_ toggles: UserPreferences.TimeSlotToggles) -> Bool {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 7..<9:  return toggles.morning
        case 9..<12: return toggles.forenoon
        case 12..<14: return toggles.midday
        case 14..<18: return toggles.afternoon
        case 18..<22: return toggles.evening
        default: return false  // 深夜不推
        }
    }

    /// 清理 7 天前的旧提醒，防止 SwiftData 无限膨胀
    private func cleanupOldReminders() {
        guard let modelContext else { return }
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
        let descriptor = FetchDescriptor<ReminderItem>(
            predicate: #Predicate { $0.timestamp < cutoff }
        )
        do {
            let old = try modelContext.fetch(descriptor)
            old.forEach { modelContext.delete($0) }
            if !old.isEmpty {
                try modelContext.save()
            }
        } catch {
            print("Failed to cleanup old reminders: \(error)")
        }
    }
}
