// V1.2 — 本地信号感知提醒引擎
// 无需联网，根据时间/星期/电量/偏好权重从内容池选择

import Foundation
import UIKit

final class MockReminderEngine {
    static let shared = MockReminderEngine()
    private init() {}

    // MARK: - 去重

    private var recentTexts: [String] = []
    private let maxRecent = 50

    private func pickUnique(from pool: [String]) -> String {
        var candidates = pool.filter { !recentTexts.contains($0) }
        if candidates.isEmpty {
            recentTexts.removeAll()
            candidates = pool
        }
        let picked = candidates.randomElement()!
        recentTexts.append(picked)
        if recentTexts.count > maxRecent {
            recentTexts.removeFirst()
        }
        return picked
    }

    // MARK: - 本地信号

    private var hour: Int { Calendar.current.component(.hour, from: .now) }
    private var weekday: Int { Calendar.current.component(.weekday, from: .now) }
    private var isWeekend: Bool { weekday == 1 || weekday == 7 } // 周日=1, 周六=7

    // MARK: - 加权随机选类别

    private func weightedCategory() -> ReminderCategory {
        let learner = PreferenceLearner.shared
        let categories: [ReminderCategory] = eligibleCategories()

        let weights = categories.map { learner.categoryWeight(for: $0) }
        let totalWeight = weights.reduce(0, +)

        var random = Double.random(in: 0..<totalWeight)
        for (category, weight) in zip(categories, weights) {
            random -= weight
            if random <= 0 { return category }
        }
        return categories.last ?? .time
    }

    /// 根据时间段 + 星期几确定候选类别
    private func eligibleCategories() -> [ReminderCategory] {
        let h = hour

        if isWeekend {
            // 周末：偏向天气和小纸条，减少效率类
            if h >= 7 && h < 10 {
                return [.weather, .general, .time]
            } else if h >= 10 && h < 18 {
                return [.weather, .time, .general]
            } else {
                return [.general, .time]
            }
        }

        // 工作日
        let dow = weekday // 2=周一, 3=周二, ..., 6=周五
        let isFriday = dow == 6
        let isMonday = dow == 2

        if h >= 7 && h < 10 {
            // 早晨
            if isMonday {
                return [.calendar, .time, .weather] // 周一多效率
            }
            return [.weather, .calendar, .time]
        } else if h >= 10 && h < 14 {
            // 上午-中午
            if isFriday {
                return [.time, .general, .calendar] // 周五轻松一点
            }
            return [.time, .calendar]
        } else if h >= 14 && h < 18 {
            // 下午
            if isFriday {
                return [.general, .time, .weather] // 周五下午放松
            }
            return [.time, .calendar, .weather]
        } else if h >= 18 && h < 22 {
            // 晚上
            return [.general, .time, .weather]
        } else {
            // 深夜
            return [.general]
        }
    }

    // MARK: - 核心：生成提醒

    /// 生成一条提醒（无电量上下文）
    func generateReminder() -> (text: String, category: ReminderCategory, isSmallNote: Bool) {
        generateReminder(batteryLevel: nil)
    }

    /// 生成一条提醒（带电量上下文）
    func generateReminder(batteryLevel: Float?) -> (text: String, category: ReminderCategory, isSmallNote: Bool) {
        // 低电量特殊处理
        if let battery = batteryLevel, battery > 0, battery < 0.15 {
            let lowBatteryTips = [
                "电量不多了，省着点用",
                "电量偏低，暂时关掉不用的功能吧",
                "快没电了，先处理重要的事",
                "电量不多了，要不要充一下",
                "低电量模式记得开一下",
            ]
            return (text: lowBatteryTips.randomElement()!, category: .general, isSmallNote: true)
        }

        // 深夜
        if hour < 7 || hour >= 23 {
            return (text: pickUnique(from: GeneralContent.items), category: .general, isSmallNote: true)
        }

        // 小纸条：每周最多 1 条，5% 概率
        if shouldGenerateSmallNote() {
            return (text: pickUnique(from: GeneralContent.items), category: .general, isSmallNote: true)
        }

        // 晚间提高小纸条概率
        if hour >= 20 && Int.random(in: 0..<4) == 0 {
            return (text: pickUnique(from: GeneralContent.items), category: .general, isSmallNote: true)
        }

        // 加权选类别
        let category = weightedCategory()

        // 从对应内容池选一条
        let pool: [String]
        switch category {
        case .weather:  pool = WeatherContent.items
        case .calendar: pool = CalendarContent.items
        case .time:     pool = TimeContent.items
        case .general:  pool = GeneralContent.items
        }

        return (text: pickUnique(from: pool), category: category, isSmallNote: false)
    }

    // MARK: - 小纸条控制

    private let smallNoteKey = "lastSmallNoteWeek"

    private func currentWeekOfYear() -> Int {
        Calendar.current.component(.weekOfYear, from: .now)
    }

    private func shouldGenerateSmallNote() -> Bool {
        let currentWeek = currentWeekOfYear()
        let lastWeek = UserDefaults.standard.integer(forKey: smallNoteKey)
        guard lastWeek != currentWeek else { return false }
        let generated = Int.random(in: 0..<100) < 5
        if generated {
            UserDefaults.standard.set(currentWeek, forKey: smallNoteKey)
        }
        return generated
    }
}
