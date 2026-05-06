import Foundation

/// V2.0: 月度报告生成
/// 每月 1 号生成上个月的使用报告
/// TODO: AI Integration — LLM 生成个性化月度总结

struct MonthlyReport {
    let year: Int
    let month: Int
    let totalReminders: Int
    let totalFeedback: Int
    let positiveRate: Double
    let topCategory: String
    let activeDays: Int
    let avgDailyReminders: Double
    let signalTrend: SignalTrend
    let summary: String
    let tips: [String]

    enum SignalTrend: String {
        case improving = "上升"
        case stable = "稳定"
        case declining = "下降"
    }
}

final class MonthlyReportGenerator {
    static let shared = MonthlyReportGenerator()

    private let defaults = UserDefaults.standard

    // MARK: - 生成报告

    /// 生成指定月份的报告
    func generateReport(year: Int, month: Int, reminders: [ReminderItem]) -> MonthlyReport {
        // 过滤当月提醒
        let calendar = Calendar.current
        let filtered = reminders.filter { item in
            let components = calendar.dateComponents([.year, .month], from: item.timestamp)
            return components.year == year && components.month == month
        }

        let total = filtered.count
        let withFeedback = filtered.filter { $0.feedbackType != nil && $0.feedbackType != "none" }
        let positive = withFeedback.filter { $0.feedbackType == "positive" || $0.feedbackType == "thumbUp" }.count
        let positiveRate = withFeedback.isEmpty ? 0 : Double(positive) / Double(withFeedback.count)

        // 活跃天数
        let activeDays = Set(filtered.map { calendar.startOfDay(for: $0.timestamp) }).count
        let daysInMonth = calendar.range(of: .day, in: .month, for: Date())?.count ?? 30
        let avgDaily = Double(total) / Double(activeDays == 0 ? 1 : activeDays)

        // 最多的类别
        let categoryCounts = Dictionary(grouping: filtered, by: { $0.category.displayName })
            .mapValues { $0.count }
        let topCategory = categoryCounts.max(by: { $0.value < $1.value })?.key ?? "无"

        // 信号趋势（模拟）
        let signalTrend: MonthlyReport.SignalTrend = positiveRate > 0.6 ? .improving : positiveRate > 0.3 ? .stable : .declining

        // 生成总结文案
        let summary = generateSummary(
            total: total, positiveRate: positiveRate, activeDays: activeDays, topCategory: topCategory
        )

        // 生成建议
        let tips = generateTips(positiveRate: positiveRate, topCategory: topCategory, avgDaily: avgDaily)

        return MonthlyReport(
            year: year,
            month: month,
            totalReminders: total,
            totalFeedback: withFeedback.count,
            positiveRate: positiveRate,
            topCategory: topCategory,
            activeDays: activeDays,
            avgDailyReminders: avgDaily,
            signalTrend: signalTrend,
            summary: summary,
            tips: tips
        )
    }

    // MARK: - 文案生成

    /// TODO: AI Integration — 用 LLM 生成个性化总结
    private func generateSummary(total: Int, positiveRate: Double, activeDays: Int, topCategory: String) -> String {
        if total == 0 {
            return "这个月还没有收到提醒，可能是通知权限没有开启。"
        }

        if positiveRate > 0.7 {
            return "这个月收到了 \\(total) 条提醒，其中 \\(Int(positiveRate * 100))% 对你有帮助。看起来提醒正在变得越来越懂你。"
        } else if positiveRate > 0.4 {
            return "这个月收到了 \\(total) 条提醒，\\(Int(positiveRate * 100))% 觉得有用。我们会继续优化推送策略。"
        } else {
            return "这个月收到了 \\(total) 条提醒，反馈不多。你可以多给反馈帮助我们更懂你。"
        }
    }

    private func generateTips(positiveRate: Double, topCategory: String, avgDaily: Double) -> [String] {
        var tips: [String] = []

        if positiveRate < 0.3 {
            tips.append("多给提醒反馈可以让我们更精准")
        }

        if avgDaily < 2 {
            tips.append("可以适当提高提醒频率，不错过重要信息")
        }

        if topCategory == "weather" {
            tips.append("你对天气提醒最关注，我们会保持这部分推送质量")
        }

        if tips.isEmpty {
            tips.append("保持当前设置，一切运行良好")
        }

        return tips
    }
}
