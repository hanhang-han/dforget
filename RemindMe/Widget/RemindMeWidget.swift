import SwiftUI
import WidgetKit

/// V2.0: 桌面小组件
/// 支持小、中、大三种尺寸
/// Pro 用户可用，免费版显示「升级 Pro」提示

// MARK: - 数据模型

struct RemindMeWidgetEntry: TimelineEntry {
    let date: Date
    let latestReminder: String?
    let reminderTime: String?
    let isPro: Bool
    let todayCount: Int
}

// MARK: - 数据提供

struct RemindMeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> RemindMeWidgetEntry {
        RemindMeWidgetEntry(date: .now, latestReminder: nil, reminderTime: nil, isPro: false, todayCount: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (RemindMeWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RemindMeWidgetEntry>) -> Void) {
        // TODO: 从 App Group 共享数据中读取最新提醒
        let entry = RemindMeWidgetEntry(
            date: .now,
            latestReminder: "坐太久了，起来走走",
            reminderTime: "14:22",
            isPro: true,
            todayCount: 3
        )

        // 每 30 分钟刷新一次
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - 小组件视图

struct RemindMeWidgetView: View {
    let entry: RemindMeWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        case .systemLarge:
            largeWidget
        default:
            smallWidget
        }
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("灵动提醒")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            if let reminder = entry.latestReminder, entry.isPro {
                Text(reminder)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
            } else if entry.isPro {
                Text("暂无提醒")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
            } else {
                Text("升级 Pro 解锁小组件")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let time = entry.reminderTime, entry.isPro {
                Text(time)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("灵动提醒")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                if entry.todayCount > 0 {
                    Text("今天 \(entry.todayCount) 条")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }

            if let reminder = entry.latestReminder, entry.isPro {
                Text(reminder)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            } else {
                Text("暂无新提醒")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
    }

    // MARK: - Large Widget

    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("灵动提醒")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            // TODO: 显示最近 4-5 条提醒
            VStack(spacing: 10) {
                if let reminder = entry.latestReminder, entry.isPro {
                    reminderRow(text: reminder, time: entry.reminderTime)
                    reminderRow(text: "上午有个会议别忘了", time: "08:30")
                    reminderRow(text: "今天气温变化较大", time: "07:15")
                } else {
                    Text("暂无提醒")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text("今天 \(entry.todayCount) 条提醒")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
    }

    private func reminderRow(text: String, time: String?) -> some View {
        HStack(spacing: 8) {
            if let time {
                Text(time)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 42, alignment: .leading)
            }

            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }
}

// MARK: - Widget 入口

struct RemindMeWidget: Widget {
    let kind = "RemindMeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RemindMeWidgetProvider()) { entry in
            RemindMeWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(.systemBackground)
                }
        }
        .configurationDisplayName("灵动提醒")
        .description("在桌面查看最新提醒")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
