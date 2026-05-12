// V2.0 — Quiet Luxury AI 对话页面
import SwiftUI

struct AIDialogView: View {
    @StateObject private var dialogService = AIDialogService.shared
    @State private var inputText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 消息列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(dialogService.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            if dialogService.isTyping {
                                HStack {
                                    Text("正在思考...")
                                        .font(QLDesign.Font.body(14))
                                        .foregroundStyle(QLDesign.Color.secondaryText)
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.7)
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .onChange(of: dialogService.messages.count) { _, _ in
                        if let last = dialogService.messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // 输入框
                Rectangle()
                    .fill(QLDesign.Color.border)
                    .frame(height: 0.5)

                HStack(spacing: 12) {
                    TextField("说点什么来调整提醒...", text: $inputText)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(QLDesign.Color.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(QLDesign.Color.border, lineWidth: 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .onSubmit { sendMessage() }

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(inputText.isEmpty ? QLDesign.Color.secondaryText : QLDesign.Color.primaryText)
                    }
                    .disabled(inputText.isEmpty || dialogService.isTyping)
                    .padding(.trailing, 12)
                }
                .padding(.vertical, 8)
                .background(QLDesign.Color.background)
            }
            .background(QLDesign.Color.background)
            .navigationTitle("对话")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let text = inputText
        inputText = ""
        Task {
            await dialogService.sendUserMessage(text)
        }
    }
}

// MARK: - 消息气泡

struct MessageBubble: View {
    let message: AIDialogService.ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .assistant {
                Image(systemName: "bell.and.waves.left.and.right")
                    .font(.system(size: 14))
                    .foregroundStyle(QLDesign.Color.secondaryText)
                    .frame(width: 28, height: 28)
                    .background(QLDesign.Color.surface)
                    .overlay(Circle().stroke(QLDesign.Color.border, lineWidth: 0.5))
                    .clipShape(Circle())
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(QLDesign.Font.body(15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(message.role == .user ? SwiftUI.Color.white.opacity(0.15) : QLDesign.Color.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(QLDesign.Color.border, lineWidth: 0.5)
                    )

                Text(message.timestamp, style: .time)
                    .font(QLDesign.Font.mono(11))
                    .foregroundStyle(QLDesign.Color.labelText)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
    }
}
