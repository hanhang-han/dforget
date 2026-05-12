// V2.0 — 轻量反馈提醒卡片
// 点击卡片直接反馈，无半屏 Modal
import SwiftUI

struct ReminderCardView: View {
    let item: ReminderItem
    let onTap: () -> Void
    let onFeedback: (String) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 分类图标
            Image(systemName: item.category.iconName)
                .font(QLDesign.Font.bodyMedium(16))
                .foregroundStyle(item.isRead ? QLDesign.Color.secondaryText : QLDesign.Color.primaryText)
                .frame(width: 24, height: 24)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                // 时间
                Text(item.timestamp, style: .time)
                    .font(QLDesign.Font.mono(12))
                    .foregroundStyle(QLDesign.Color.secondaryText)

                // 文案
                Text(item.text)
                    .font(item.isRead ? QLDesign.Font.body(15) : QLDesign.Font.bodyMedium(15))
                    .foregroundStyle(item.isRead ? QLDesign.Color.secondaryText : QLDesign.Color.primaryText)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                // 分类标签 + 快速反馈
                HStack(spacing: 8) {
                    Text(item.category.displayName)
                        .font(QLDesign.Font.label(11))
                        .foregroundStyle(QLDesign.Color.labelText)

                    Spacer()

                    if item.feedbackType == "none" {
                        // 快速反馈按钮
                        Button { onFeedback("positive") } label: {
                            Image(systemName: "hand.thumbsup")
                                .font(.system(size: 12))
                                .foregroundStyle(QLDesign.Color.secondaryText)
                        }
                        .buttonStyle(.plain)

                        Button { onFeedback("negative") } label: {
                            Image(systemName: "hand.thumbsdown")
                                .font(.system(size: 12))
                                .foregroundStyle(QLDesign.Color.secondaryText)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text(feedbackEmoji(item.feedbackType))
                            .font(.system(size: 11))
                    }
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: QLDesign.Shape.cardRadius, style: .continuous)
                .fill(QLDesign.Color.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: QLDesign.Shape.cardRadius, style: .continuous)
                .stroke(QLDesign.Color.border, lineWidth: 0.5)
        )
    }

    private func feedbackEmoji(_ type: String) -> String {
        switch type {
        case "positive": return "👍"
        case "neutral": return "🙂"
        case "negative": return "👎"
        default: return ""
        }
    }
}
