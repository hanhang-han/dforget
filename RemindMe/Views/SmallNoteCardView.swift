import SwiftUI

struct SmallNoteCardView: View {
    let item: ReminderItem
    let onTap: () -> Void
    let onFeedback: (String) -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 顶部装饰线
                HStack {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(QLDesign.Color.border)
                        .frame(width: 20, height: 3)
                    Spacer()
                    Text(item.timestamp, style: .time)
                        .font(QLDesign.Font.mono(11))
                        .foregroundStyle(QLDesign.Color.secondaryText)
                }

                // 文案 — 手写感
                Text(item.text)
                    .font(QLDesign.Font.serif(15).italic())
                    .foregroundStyle(item.isRead ? QLDesign.Color.secondaryText : QLDesign.Color.primaryText)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)

                // 底部标签
                HStack {
                    Text("小纸条")
                        .font(QLDesign.Font.label(11))
                        .foregroundStyle(QLDesign.Color.labelText)
                    Spacer()
                    if item.feedbackType != "none" {
                        Text(feedbackEmoji(item.feedbackType))
                            .font(.system(size: 11))
                    }
                }
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
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onFeedback("positive")
            } label: {
                Label("温暖", systemImage: "heart")
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
