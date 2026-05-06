import SwiftUI

struct ReminderCardView: View {
    let item: ReminderItem
    let onTap: () -> Void
    let onFeedback: (String) -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // 分类图标
                Image(systemName: item.category.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(item.isRead ? .secondary : Color(.label))
                    .frame(width: 24, height: 24)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 6) {
                    // 时间
                    Text(item.timestamp, style: .time)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)

                    // 文案
                    Text(item.text)
                        .font(.system(size: 15, weight: item.isRead ? .regular : .medium))
                        .foregroundStyle(item.isRead ? .secondary : Color(.label))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    // 分类标签
                    HStack(spacing: 8) {
                        Text(item.category.displayName)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)

                        if item.feedbackType != "none" {
                            Text(feedbackEmoji(item.feedbackType))
                                .font(.system(size: 11))
                        }
                    }
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(item.isRead ? Color(.systemGray6) : Color(.white))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(item.isRead ? Color.clear : Color(.systemGray5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onFeedback("positive")
            } label: {
                Label("有用 👍", systemImage: "hand.thumbsup")
            }
            Button {
                onFeedback("neutral")
            } label: {
                Label("一般 🙂", systemImage: "face.smiling")
            }
            Button {
                onFeedback("negative")
            } label: {
                Label("没帮助 👎", systemImage: "hand.thumbsdown")
            }
        }
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
