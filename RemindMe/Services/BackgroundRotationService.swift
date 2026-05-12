// V1.1 — 后台轮换服务
// App 进入后台后，通过 BGTaskScheduler 定期唤醒更新灵动岛

import Foundation
import UIKit
import BackgroundTasks

@MainActor
final class BackgroundRotationService {
    static let shared = BackgroundRotationService()

    private let taskIdentifier = "com.hanhang.remindme.rotation"
    private let seenKey = "bg_seen_today"
    private let dateKey = "bg_last_date"

    private let contextEngine = ContextEngine.shared
    private let liveActivityService = LiveActivityService.shared

    private init() {}

    // MARK: - 注册后台任务

    func register() {
        UIDevice.current.isBatteryMonitoringEnabled = true

        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            Task { @MainActor in
                await self.handleBackgroundTask(task as! BGAppRefreshTask)
            }
        }
    }

    // MARK: - 调度下一次后台刷新

    func scheduleNextRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background refresh: \(error)")
        }
    }

    // MARK: - 处理后台任务（async 等待 Live Activity 更新完成）

    private func handleBackgroundTask(_ task: BGAppRefreshTask) async {
        // 先调度下一次，防止任务完成后系统不再唤醒
        scheduleNextRefresh()

        // 过期处理
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        // 执行轮换并等待 Live Activity 更新
        await rotateInBackground()

        task.setTaskCompleted(success: true)
    }

    // MARK: - 后台轮换逻辑

    private func rotateInBackground() async {
        checkDayRollover()

        var seen = loadSeenToday()
        UIDevice.current.isBatteryMonitoringEnabled = true
        let battery = UIDevice.current.batteryLevel >= 0 ? UIDevice.current.batteryLevel : nil

        let result = contextEngine.rotate(seenToday: seen, batteryLevel: battery)

        if let sceneId = result.sceneId {
            seen.insert(sceneId)
            saveSeenToday(seen)
        }

        // 更新灵动岛（等待完成）
        await liveActivityService.updateLiveActivity(reminderText: result.text)

        // 同步到 Widget
        let store = SharedDataStore.shared
        store.updateLatestReminder(
            text: result.text,
            category: result.category.displayName,
            timestamp: Date()
        )
        store.reloadWidgets()
    }

    // MARK: - 去重持久化

    private func checkDayRollover() {
        let today = DateFormatter.localizedString(from: .now, dateStyle: .short, timeStyle: .none)
        let saved = UserDefaults.standard.string(forKey: dateKey) ?? ""
        if today != saved {
            UserDefaults.standard.set(today, forKey: dateKey)
            UserDefaults.standard.removeObject(forKey: seenKey)
        }
    }

    private func loadSeenToday() -> Set<String> {
        let array = UserDefaults.standard.stringArray(forKey: seenKey) ?? []
        return Set(array)
    }

    private func saveSeenToday(_ seen: Set<String>) {
        UserDefaults.standard.set(Array(seen), forKey: seenKey)
    }
}
