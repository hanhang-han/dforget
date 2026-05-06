import ActivityKit
import SwiftUI
import WidgetKit

struct RemindMeActivity: Widget {
    let kind = "RemindMeActivity"

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RemindMeAttributes.self) { context in
            // Lock Screen / Banner
            HStack {
                Image(systemName: "bell.fill")
                    .font(.system(size: 14))
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.reminderText)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                    Text(context.state.timestamp, style: .relative)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .activityBackgroundTint(Color(red: 0.1, green: 0.1, blue: 0.1))

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Leading
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                        .padding(.leading, 12)
                }
                // Expanded Center
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("灵动提醒")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(context.state.reminderText)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }
                    .padding(.leading, 4)
                }
                // Expanded Trailing
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.timestamp, style: .relative)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 12)
                }
                // Expanded Bottom
                DynamicIslandExpandedRegion(.bottom) {
                    EmptyView()
                }
            } compactLeading: {
                Image(systemName: "bell.fill")
                    .font(.system(size: 12))
            } compactTrailing: {
                Text(context.state.timestamp, style: .relative)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } minimal: {
                Image(systemName: "bell.fill")
                    .font(.system(size: 12))
            }
            .widgetURL(URL(string: "remindme://liveActivity"))
            .keylineTint(Color(red: 0.1, green: 0.1, blue: 0.1))
        }
    }
}

// Widget Bundle 用于注册 Widget
@main
struct RemindMeWidgetBundle: WidgetBundle {
    var body: some Widget {
        RemindMeActivity()
    }
}
