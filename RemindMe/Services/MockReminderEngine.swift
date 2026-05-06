import Foundation

// TODO: AI Integration — 接入真实 AI 模型生成个性化提醒内容
// 目前使用本地模板随机生成模拟提醒

final class MockReminderEngine {
    static let shared = MockReminderEngine()

    private init() {}

    // MARK: - 天气提醒

    private let weatherReminders = [
        "今天气温变化较大，出门记得带件外套。",
        "下午可能有阵雨，记得带伞。",
        "空气质量不错，适合户外活动。",
        "今晚温度会降到 10°C 以下，注意保暖。",
        "紫外线指数偏高，出门注意防晒。",
        "明天多云转晴，是个出门的好天气。",
        "湿度较高，衣服不容易晾干。",
        "今天风比较大，骑行注意安全。",
    ]

    // MARK: - 日历提醒

    private let calendarReminders = [
        "今天有个会议别忘了准备材料。",
        "距离下一个日程还有一小时，提前准备。",
        "今天的事比较多，记得合理分配时间。",
        "下午有个待办事项即将到期。",
        "今天的日程已经排满了，注意节奏。",
        "会议结束后记得整理纪要。",
    ]

    // MARK: - 时间提醒

    private let timeReminders = [
        "站起来活动一下，久坐对身体不好。",
        "该喝水了，保持每天八杯水的好习惯。",
        "中午了，记得吃午饭。",
        "下午容易犯困，可以站起来走走。",
        "一天过半了，检查一下待办清单。",
        "快到下班时间了，整理一下今天的工作。",
        "晚上早点休息，明天还有新的开始。",
        "现在是下午茶时间，适当放松一下。",
        "别忘了做几分钟深呼吸，缓解压力。",
        "该保护眼睛了，看看远处休息一下。",
    ]

    // MARK: - 日常提醒（小纸条）

    private let smallNoteReminders = [
        "你今天做得很好，继续保持。",
        "生活不是比赛，偶尔慢下来也没关系。",
        "别忘了给家人打个电话。",
        "今天有什么值得开心的小事吗？",
        "试着对陌生人微笑一下。",
        "你已经很努力了，不要对自己太苛刻。",
        "给自己买杯好喝的咖啡吧。",
        "记录下今天的一个小成就。",
    ]

    // MARK: - 生成逻辑

    /// 根据当前时间段生成合适的提醒
    /// 小纸条：每周最多 1 条，不重复
    /// V1.1: 根据用户偏好过滤不受欢迎的类别
    func generateReminder() -> (text: String, category: ReminderCategory, isSmallNote: Bool) {
        let hour = Calendar.current.component(.hour, from: .now)

        // 检查推送是否暂停（信号值过低）
        if PreferenceLearner.shared.isPushPaused {
            // 暂停期间只生成小纸条（非打扰）
            return (
                text: pickUniqueSmallNote(),
                category: .general,
                isSmallNote: true
            )
        }

        // 小纸条逻辑：每周最多 1 条，概率约 5%
        let isSmallNote = shouldGenerateSmallNote()

        if isSmallNote {
            return (
                text: pickUniqueSmallNote(),
                category: .general,
                isSmallNote: true
            )
        }

        // 根据时间段优先生成不同类别
        let category: ReminderCategory
        if hour >= 7 && hour < 10 {
            // 早晨 — 天气 + 日历
            category = Bool.random() ? .weather : .calendar
        } else if hour >= 10 && hour < 12 {
            // 上午 — 时间提醒
            category = .time
        } else if hour >= 12 && hour < 14 {
            // 中午 — 时间提醒
            category = .time
        } else if hour >= 14 && hour < 18 {
            // 下午 — 混合
            category = [.time, .calendar, .weather].randomElement()!
        } else if hour >= 18 && hour < 22 {
            // 晚上 — 小纸条概率提高
            if Bool.random() {
                return (
                    text: smallNoteReminders.randomElement()!,
                    category: .general,
                    isSmallNote: true
                )
            }
            category = .time
        } else {
            // 深夜 — 安慰型
            return (
                text: "夜深了，早点休息吧。明天会更好。",
                category: .general,
                isSmallNote: true
            )
        }

        let text: String
        switch category {
        case .weather:
            text = weatherReminders.randomElement()!
        case .calendar:
            text = calendarReminders.randomElement()!
        case .time:
            text = timeReminders.randomElement()!
        case .general:
            text = smallNoteReminders.randomElement()!
        }

        return (text: text, category: category, isSmallNote: false)
    }

    /// 每天生成 4~6 条提醒
    func generateDailyReminders() -> [(text: String, category: ReminderCategory, isSmallNote: Bool)] {
        let count = Int.random(in: 4...6)
        var reminders: [(text: String, category: ReminderCategory, isSmallNote: Bool)] = []

        for _ in 0..<count {
            reminders.append(generateReminder())
        }

        return reminders
    }

    // MARK: - 小纸条控制

    private let smallNoteKey = "lastSmallNoteWeek"
    private var lastSmallNoteWeek: Int {
        let defaults = UserDefaults.standard
        return defaults.integer(forKey: smallNoteKey)
    }

    private func currentWeekOfYear() -> Int {
        let calendar = Calendar.current
        return calendar.component(.weekOfYear, from: .now)
    }

    /// 每周最多 1 条小纸条，概率约 5%
    private func shouldGenerateSmallNote() -> Bool {
        let currentWeek = currentWeekOfYear()
        guard lastSmallNoteWeek != currentWeek else { return false }
        return Int.random(in: 0..<100) < 5
    }

    /// 从小纸条池中随机选一条，尽量避免短期重复
    private func pickUniqueSmallNote() -> String {
        let defaults = UserDefaults.standard
        let lastNote = defaults.string(forKey: "lastSmallNoteText") ?? ""

        var candidates = smallNoteReminders.filter { $0 != lastNote }
        if candidates.isEmpty { candidates = smallNoteReminders }

        let note = candidates.randomElement()!
        defaults.set(note, forKey: "lastSmallNoteText")
        defaults.set(currentWeekOfYear(), forKey: smallNoteKey)
        return note
    }
}
