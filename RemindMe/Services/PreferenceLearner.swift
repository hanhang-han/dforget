import Foundation

/// V1.1: 用户偏好学习引擎
/// 根据用户反馈动态调整提醒策略
/// TODO: AI Integration — V2.0 接入 LLM 做更精准的偏好推断

final class PreferenceLearner {
    static let shared = PreferenceLearner()

    private let defaults = UserDefaults.standard

    // MARK: - 信号值

    /// 信号值范围 -1.0 到 +1.0
    private var signalValue: Double {
        get { defaults.double(forKey: "signal_value") }
        set { defaults.set(newValue, forKey: "signal_value") }
    }

    /// 信号值暂停阈值
    static let pauseThreshold = 0.10
    /// 信号值恢复阈值
    static let resumeThreshold = 0.30

    /// 加权移动平均系数
    private let alpha: Double = 0.3

    /// 是否暂停推送
    var isPushPaused: Bool {
        return signalValue < Self.pauseThreshold
    }

    // MARK: - 反馈权重

    enum FeedbackWeight {
        static let thumbUp: Double = 0.15
        static let thumbDown: Double = -0.25
        static let dismiss: Double = -0.10
        static let ignore: Double = 0.02      // 24h 无互动
        static let silence: Double = 0.05      // 沉默接受
    }

    // MARK: - 更新信号值

    /// 处理用户反馈
    func processFeedback(_ type: String) {
        let weight: Double
        switch type {
        case "positive", "thumbUp":
            weight = FeedbackWeight.thumbUp
        case "negative", "thumbDown":
            weight = FeedbackWeight.thumbDown
        case "neutral":
            weight = FeedbackWeight.silence
        default:
            weight = FeedbackWeight.silence
        }

        updateSignal(delta: weight)
    }

    /// 处理通知被忽略（24h 未互动）
    func processIgnored() {
        updateSignal(delta: FeedbackWeight.ignore)
    }

    /// 更新信号值（加权移动平均）
    private func updateSignal(delta: Double) {
        let prev = signalValue == 0 ? 0.5 : signalValue
        let next = prev + alpha * (delta - prev)
        let clamped = max(-1.0, min(1.0, next))
        signalValue = clamped

        print("[PreferenceLearner] Signal: \(prev) → \(clamped) (delta=\(delta))")

        if clamped < Self.pauseThreshold {
            print("[PreferenceLearner] Push PAUSED")
        } else if clamped >= Self.resumeThreshold {
            print("[PreferenceLearner] Push RESUMED")
        }
    }

    // MARK: - 类别偏好

    /// 记录各类别的反馈得分
    func recordCategoryFeedback(category: String, positive: Bool) {
        let key = "category_score_\(category)"
        let current = defaults.double(forKey: key)
        let delta = positive ? 0.1 : -0.15
        let next = max(-1.0, min(1.0, current + delta))
        defaults.set(next, forKey: key)
    }

    /// 获取类别偏好（得分从高到低排序）
    func getSortedCategories() -> [(category: String, score: Double)] {
        let allCategories = ["weather", "calendar", "time", "health", "general"]
        var scored: [(String, Double)] = []

        for cat in allCategories {
            let score = defaults.double(forKey: "category_score_\(cat)")
            scored.append((category: cat, score: score))
        }

        return scored.sorted { $0.score > $1.score }
    }

    /// 获取最低偏好类别（避免频繁推送）
    func getDislikedCategories() -> [String] {
        getSortedCategories()
            .filter { $0.score < -0.3 }
            .map { $0.category }
    }

    // MARK: - 时段偏好

    /// 记录哪个时段用户活跃（点击/阅读提醒）
    func recordActiveHour(_ hour: Int) {
        let key = "active_hour_\(hour)"
        let count = defaults.integer(forKey: key)
        defaults.set(count + 1, forKey: key)
    }

    /// 获取用户最活跃的小时
    func getTopActiveHours(limit: Int = 3) -> [Int] {
        var hours: [(hour: Int, count: Int)] = []

        for h in 0..<24 {
            let count = defaults.integer(forKey: "active_hour_\(h)")
            if count > 0 {
                hours.append((hour: h, count: count))
            }
        }

        return hours.sorted { $0.count > $1.count }.prefix(limit).map { $0.hour }
    }

    // MARK: - 冷启动

    /// 获取安装天数
    var daysSinceInstall: Int {
        let installDate = defaults.object(forKey: "install_date") as? Date ?? Date()
        let days = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        return max(days, 0)
    }

    /// 获取冷启动阶段
    var coldStartPhase: ColdStartPhase {
        let days = daysSinceInstall
        if days <= 3 { return .conservative }
        if days <= 7 { return .exploring }
        return .normal
    }

    /// 冷启动阶段对应的每日推送上限
    var dailyPushLimit: Int {
        switch coldStartPhase {
        case .conservative: return 3
        case .exploring: return 5
        case .normal: return 6
        }
    }

    enum ColdStartPhase: String {
        case conservative = "Day 1-3: 保守期"
        case exploring = "Day 4-7: 试探期"
        case normal = "Day 8+: 正常期"
    }
}
