import SwiftUI

struct ReminderCardView: View {
    let item: ReminderItem
    let onTap: () -> Void
    let onFeedback: (String) -> Void

    @State private var showFeedbackToast = false
    @State private var feedbackToastText = ""

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
                handleFeedback("positive")
            } label: {
                Label("有用", systemImage: "hand.thumbsup")
            }
            Button {
                handleFeedback("neutral")
            } label: {
                Label("一般", systemImage: "hand.thumbsup")
            }
            Button {
                handleFeedback("negative")
            } label: {
                Label("没帮助", systemImage: "hand.thumbsdown")
            }
        }
        .overlay(alignment: .bottom) {
            if showFeedbackToast {
                Text(feedbackToastText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(.label).opacity(0.7)))
                    .padding(.bottom, -28)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showFeedbackToast)
    }

    // MARK: - V1.1 快速反馈

    private func handleFeedback(_ type: String) {
        onFeedback(type)
        feedbackToastText = feedbackToastMessage(type)
        showFeedbackToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showFeedbackToast = false
        }
    }

    private func feedbackToastMessage(_ type: String) -> String {
        switch type {
        case "positive": return "收到，会多推类似的"
        case "negative": return "收到，会减少这类推送"
        case "neutral": return "收到"
        default: return ""
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
