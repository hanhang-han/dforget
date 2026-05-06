import SwiftUI

struct SmallNoteCardView: View {
    let item: ReminderItem
    let onTap: () -> Void
    let onFeedback: (String) -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 顶部小装饰线
                HStack {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color(.systemGray4))
                        .frame(width: 20, height: 3)
                    Spacer()
                    Text(item.timestamp, style: .time)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                // 文案 — 手写感
                Text(item.text)
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(item.isRead ? .secondary : Color(.label))
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)

                // 底部标签
                HStack {
                    Text("小纸条")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if item.feedbackType != "none" {
                        Text(feedbackEmoji(item.feedbackType))
                            .font(.system(size: 11))
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(item.isRead ? Color(.systemGray6) : Color(.systemBackground))
                    .shadow(
                        color: Color(.systemGray4).opacity(0.5),
                        radius: 1,
                        x: 1,
                        y: 1
                    )
            )
            .overlay(
                // 模拟纸张纹理的细边框
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), style: StrokeStyle(lineWidth: 0.5, dash: [4, 2]))
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onFeedback("positive")
            } label: {
                Label("温暖 ❤️", systemImage: "heart")
            }
            Button {
                onFeedback("neutral")
            } label: {
                Label("一般", systemImage: "hand.raised")
            }
        }
    }

    private func feedbackEmoji(_ type: String) -> String {
        switch type {
        case "positive": return "❤️"
        case "neutral": return "👋"
        default: return ""
        }
    }
}
