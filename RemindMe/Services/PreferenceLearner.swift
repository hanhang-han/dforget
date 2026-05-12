import Foundation

/// V1.2: 用户偏好学习引擎
/// 显式反馈 + 隐式行为信号，调整类别配比（不暂停）

final class PreferenceLearner {
    static let shared = PreferenceLearner()
    private let defaults = UserDefaults.standard

    // MARK: - 学习速率

    /// 加权移动平均系数（低速率，避免少数反馈大幅改变体验）
    private let alpha: Double = 0.1

    // MARK: - 信号值（整体活跃度，供参考）

    var signalValue: Double {
        get { defaults.double(forKey: "signal_value") }
        set { defaults.set(newValue, forKey: "signal_value") }
    }

    /// 信号值较低时（仅供设置页展示，不再用于暂停推送）
    var isPushPaused: Bool {
        return signalValue < 0.10
    }

    // MARK: - 显式反馈（用户主动 👍👎）

    enum ExplicitWeight {
        static let thumbUp: Double = 0.08
        static let thumbDown: Double = -0.10
    }

    // MARK: - 隐式信号（用户行为推断）

    enum ImplicitWeight {
        static let refresh: Double = -0.04   // 灵动岛"换一个" = 这条没用
        static let appOpen: Double = 0.04    // 打开 App = 被内容吸引
    }

    // MARK: - 更新信号值

    func processFeedback(_ type: String) {
        let weight: Double
        switch type {
        case "positive", "thumbUp":
            weight = ExplicitWeight.thumbUp
        case "negative", "thumbDown":
            weight = ExplicitWeight.thumbDown
        default:
            return
        }
        updateSignal(delta: weight)
    }

    /// 隐式信号：灵动岛"换一个"
    func processRefresh() {
        updateSignal(delta: ImplicitWeight.refresh)
    }

    /// 隐式信号：用户打开 App
    func processAppOpen() {
        updateSignal(delta: ImplicitWeight.appOpen)
    }

    private func updateSignal(delta: Double) {
        let prev = signalValue == 0 ? 0.5 : signalValue
        let next = prev + alpha * (delta - prev)
        let clamped = max(-1.0, min(1.0, next))
        signalValue = clamped
    }

    // MARK: - 类别偏好

    /// 记录显式反馈对类别的影响
    func recordCategoryFeedback(category: String, positive: Bool) {
        let delta = positive ? 0.06 : -0.08
        updateCategoryScore(category: category, delta: delta)
    }

    /// 记录隐式信号对类别的影响（更温和）
    func recordCategoryImplicit(category: String, positive: Bool) {
        let delta = positive ? 0.03 : -0.03
        updateCategoryScore(category: category, delta: delta)
    }

    private func updateCategoryScore(category: String, delta: Double) {
        let key = "category_score_\(category)"
        let current = defaults.double(forKey: key)
        let next = max(-1.0, min(1.0, current + delta))
        defaults.set(next, forKey: key)
    }

    /// 获取类别选择权重（0.2 ~ 2.5）
    func categoryWeight(for category: ReminderCategory) -> Double {
        let key = "category_score_\(category.displayName)"
        let score = defaults.double(forKey: key)
        let baseWeight = 1.0 + score * 0.75
        return max(0.2, min(2.5, baseWeight))
    }

    /// 获取类别偏好排序（供外部展示用）
    func getSortedCategories() -> [(category: String, score: Double)] {
        let allCategories = ReminderCategory.allCases.map { $0.displayName }
        var scored: [(category: String, score: Double)] = []
        for cat in allCategories {
            let score = defaults.double(forKey: "category_score_\(cat)")
            scored.append((category: cat, score: score))
        }
        return scored.sorted { $0.score > $1.score }
    }

    // MARK: - 时段偏好

    func recordActiveHour(_ hour: Int) {
        let key = "active_hour_\(hour)"
        let count = defaults.integer(forKey: key)
        defaults.set(count + 1, forKey: key)
    }

    func getTopActiveHours(limit: Int = 3) -> [Int] {
        var hours: [(hour: Int, count: Int)] = []
        for h in 0..<24 {
            let count = defaults.integer(forKey: "active_hour_\(h)")
            if count > 0 { hours.append((hour: h, count: count)) }
        }
        return hours.sorted { $0.count > $1.count }.prefix(limit).map { $0.hour }
    }

    // MARK: - 冷启动

    var daysSinceInstall: Int {
        let installDate = defaults.object(forKey: "install_date") as? Date ?? Date()
        return max(Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0, 0)
    }

    var coldStartPhase: ColdStartPhase {
        let days = daysSinceInstall
        if days <= 3 { return .conservative }
        if days <= 7 { return .exploring }
        return .normal
    }

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
