// V1.2 — 精简上下文引擎
// 纯本地信号：时间 + 星期几 + 电量 + 偏好权重，不依赖网络

import Foundation
import UIKit

// MARK: - 展示优先级

enum DisplayPriority: Int, Comparable {
    case liveActivity = 0
    case notification = 1
    case appOnly = 2

    static func < (lhs: DisplayPriority, rhs: DisplayPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - 融合提醒结构体

struct FusedReminder {
    let text: String
    let category: ReminderCategory
    let secondaryCategory: ReminderCategory?
    let isSmallNote: Bool
    let displayPriority: DisplayPriority
    let sceneId: String?

    init(text: String, category: ReminderCategory, secondaryCategory: ReminderCategory? = nil, isSmallNote: Bool, displayPriority: DisplayPriority, sceneId: String? = nil) {
        self.text = text
        self.category = category
        self.secondaryCategory = secondaryCategory
        self.isSmallNote = isSmallNote
        self.displayPriority = displayPriority
        self.sceneId = sceneId
    }
}

// MARK: - ContextEngine

@MainActor
final class ContextEngine {
    static let shared = ContextEngine()

    private let mockEngine = MockReminderEngine.shared
    private let preferenceLearner = PreferenceLearner.shared
    private let defaults = UserDefaults.standard

    // MARK: - 去重

    private let dedupKey = "context_engine_seen_hashes"
    private let maxDedupEntries = 80

    private func seenHashes() -> Set<String> {
        let array = defaults.stringArray(forKey: dedupKey) ?? []
        return Set(array)
    }

    private func markSeen(_ hash: String) {
        var array = defaults.stringArray(forKey: dedupKey) ?? []
        array.append(hash)
        if array.count > maxDedupEntries {
            array = Array(array.suffix(maxDedupEntries))
        }
        defaults.set(array, forKey: dedupKey)
    }

    private func isSeen(_ text: String) -> Bool {
        seenHashes().contains(text)
    }

    // MARK: - 核心生成

    /// 生成一条提醒
    func generate() -> FusedReminder {
        let result = mockEngine.generateReminder(batteryLevel: currentBatteryLevel())
        let priority: DisplayPriority = result.isSmallNote ? .appOnly : .liveActivity
        return FusedReminder(
            text: result.text,
            category: result.category,
            isSmallNote: result.isSmallNote,
            displayPriority: priority
        )
    }

    // MARK: - 场景轮换（每 10 分钟调用一次）

    func rotate(seenToday: Set<String>, batteryLevel: Float?) -> FusedReminder {
        let battery = batteryLevel ?? currentBatteryLevel()

        // 最多 3 次尝试去重
        for _ in 0..<3 {
            let result = mockEngine.generateReminder(batteryLevel: battery)

            if !isSeen(result.text) {
                markSeen(result.text)
                let priority: DisplayPriority = result.isSmallNote ? .appOnly : .liveActivity
                return FusedReminder(
                    text: result.text,
                    category: result.category,
                    isSmallNote: result.isSmallNote,
                    displayPriority: priority,
                    sceneId: result.text.prefix(16).description
                )
            }
        }

        // 去重失败，直接返回一条
        let fallback = mockEngine.generateReminder(batteryLevel: battery)
        return FusedReminder(
            text: fallback.text,
            category: fallback.category,
            isSmallNote: fallback.isSmallNote,
            displayPriority: .appOnly
        )
    }

    // MARK: - 辅助

    private func currentBatteryLevel() -> Float {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        return level >= 0 ? level : -1
    }
}
