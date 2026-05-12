import SwiftUI
import WidgetKit

/// V2.0: Quiet Luxury 桌面小组件

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
        completion(readSharedEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RemindMeWidgetEntry>) -> Void) {
        let entry = readSharedEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func readSharedEntry() -> RemindMeWidgetEntry {
        let store = SharedDataStore.shared
        return RemindMeWidgetEntry(
            date: .now,
            latestReminder: store.latestReminderText,
            reminderTime: store.latestReminderTime,
            isPro: true,
            todayCount: store.todayCount
        )
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
        case .accessoryInline:
            inlineWidget
        default:
            smallWidget
        }
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("灵动提醒")
                .font(QLDesign.Font.label(11))
                .foregroundStyle(QLDesign.Color.secondaryText)

            if let reminder = entry.latestReminder, entry.isPro {
                Text(reminder)
                    .font(QLDesign.Font.body(14))
                    .foregroundStyle(QLDesign.Color.primaryText)
                    .lineLimit(3)
            } else if entry.isPro {
                Text("暂无提醒")
                    .font(QLDesign.Font.body(13))
                    .foregroundStyle(QLDesign.Color.labelText)
            } else {
                Text("升级 Pro 解锁小组件")
                    .font(QLDesign.Font.body(12))
                    .foregroundStyle(QLDesign.Color.secondaryText)
            }

            Spacer()

            if let time = entry.reminderTime, entry.isPro {
                Text(time)
                    .font(QLDesign.Font.mono(11))
                    .foregroundStyle(QLDesign.Color.labelText)
            }
        }
        .padding(16)
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("灵动提醒")
                    .font(QLDesign.Font.label(11))
                    .foregroundStyle(QLDesign.Color.secondaryText)

                Spacer()

                if entry.todayCount > 0 {
                    Text("今天 \(entry.todayCount) 条")
                        .font(QLDesign.Font.mono(11))
                        .foregroundStyle(QLDesign.Color.labelText)
                }
            }

            if let reminder = entry.latestReminder, entry.isPro {
                Text(reminder)
                    .font(QLDesign.Font.body(15))
                    .foregroundStyle(QLDesign.Color.primaryText)
                    .lineLimit(2)
            } else {
                Text("暂无新提醒")
                    .font(QLDesign.Font.body(14))
                    .foregroundStyle(QLDesign.Color.secondaryText)
            }
        }
        .padding(16)
    }

    // MARK: - Lock Screen Inline Widget

    @ViewBuilder
    private var inlineWidget: some View {
        if let reminder = entry.latestReminder, entry.isPro {
            HStack(spacing: 4) {
                Image(systemName: "bell.fill")
                Text(reminder)
                    .lineLimit(1)
            }
        } else {
            Text("灵动提醒")
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
                    QLDesign.Color.background
                }
        }
        .configurationDisplayName("灵动提醒")
        .description("在桌面查看最新提醒")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline])
    }
}
