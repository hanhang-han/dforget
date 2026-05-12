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
                    .foregroundStyle(QLDesign.Color.primaryText)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.reminderText)
                        .font(QLDesign.Font.bodyMedium(14))
                        .foregroundStyle(QLDesign.Color.primaryText)
                        .lineLimit(1)
                    Text(context.state.timestamp, style: .relative)
                        .font(QLDesign.Font.mono(11))
                        .foregroundStyle(QLDesign.Color.secondaryText)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .activityBackgroundTint(QLDesign.Color.background)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Leading
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(QLDesign.Color.primaryText)
                        .padding(.leading, 12)
                }
                // Expanded Center
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("灵动提醒")
                            .font(QLDesign.Font.label(11))
                            .foregroundStyle(QLDesign.Color.secondaryText)
                        Text(context.state.reminderText)
                            .font(QLDesign.Font.bodyMedium(14))
                            .foregroundStyle(QLDesign.Color.primaryText)
                            .lineLimit(2)
                    }
                    .padding(.leading, 4)
                }
                // Expanded Trailing
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.timestamp, style: .relative)
                        .font(QLDesign.Font.mono(11))
                        .foregroundStyle(QLDesign.Color.secondaryText)
                        .padding(.trailing, 12)
                }
                // Expanded Bottom — 按钮
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        Link(destination: URL(string: "remindme://refresh")!) {
                            Text("换一个")
                                .font(QLDesign.Font.bodyMedium(13))
                                .foregroundStyle(QLDesign.Color.primaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(SwiftUI.Color.white.opacity(0.12)))
                                .overlay(Capsule().stroke(QLDesign.Color.border, lineWidth: 0.5))
                        }
                        Link(destination: URL(string: "remindme://dismiss")!) {
                            Text("关闭")
                                .font(QLDesign.Font.bodyMedium(13))
                                .foregroundStyle(QLDesign.Color.primaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(SwiftUI.Color.white.opacity(0.12)))
                                .overlay(Capsule().stroke(QLDesign.Color.border, lineWidth: 0.5))
                        }
                    }
                    .padding(.bottom, 8)
                }
            } compactLeading: {
                Image(systemName: "bell.fill")
                    .font(.system(size: 12))
            } compactTrailing: {
                Text(context.state.timestamp, style: .relative)
                    .font(QLDesign.Font.mono(11))
                    .foregroundStyle(QLDesign.Color.secondaryText)
            } minimal: {
                Image(systemName: "bell.fill")
                    .font(.system(size: 12))
            }
            .widgetURL(URL(string: "remindme://liveActivity"))
            .keylineTint(QLDesign.Color.background)
        }
    }
}

// Widget Bundle
@main
struct RemindMeWidgetBundle: WidgetBundle {
    var body: some Widget {
        RemindMeActivity()
        RemindMeWidget()
    }
}
