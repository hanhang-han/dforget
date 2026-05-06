import SwiftUI

/// V2.1: AI 对话页面
/// 用户通过自然语言调整偏好

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
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                    ProgressView()
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
                Divider()

                HStack(spacing: 12) {
                    TextField("说点什么来调整提醒...", text: $inputText)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .onSubmit { sendMessage() }

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(inputText.isEmpty ? .gray : Color(.label))
                    }
                    .disabled(inputText.isEmpty || dialogService.isTyping)
                    .padding(.trailing, 12)
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
            }
            .navigationTitle("对话")
            .navigationBarTitleDisplayMode(.inline)
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
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 15))
                    .foregroundStyle(message.role == .user ? .white : Color(.label))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        (message.role == .user ? Color(.label) : Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 16, corners: message.role == .user ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight]))
                    )

                Text(message.timestamp, style: .time)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }

            if message.role == .user {
                Spacer()
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - 辅助扩展

extension RoundedRectangle {
    init(cornerRadius: CGFloat, corners: [Corner]) {
        self.init(cornerRadius: cornerRadius, style: .continuous)
    }

    enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }
}
