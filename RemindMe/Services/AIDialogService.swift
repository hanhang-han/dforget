import Foundation

/// V2.1: AI 对话服务
/// 用户通过自然语言对话调整提醒偏好
/// V2.1 使用伪代码模拟，V3.0 接入真实 LLM
/// TODO: AI Integration — 接入 DeepSeek / GLM 对话接口

final class AIDialogService: ObservableObject {
    static let shared = AIDialogService()

    @Published var messages: [ChatMessage] = []
    @Published var isTyping = false

    // MARK: - 消息模型

    struct ChatMessage: Identifiable {
        let id = UUID()
        let role: Role
        let text: String
        let timestamp = Date()

        enum Role {
            case user
            case assistant
            case system
        }
    }

    // MARK: - 对话

    /// 发送用户消息
    func sendUserMessage(_ text: String) async {
        let userMsg = ChatMessage(role: .user, text: text)
        messages.append(userMsg)

        isTyping = true

        // 模拟 AI 响应延迟
        try? await Task.sleep(nanoseconds: 800_000_000)

        let response = generateResponse(for: text)
        let assistantMsg = ChatMessage(role: .assistant, text: response)
        messages.append(assistantMsg)

        isTyping = false
    }

    /// 生成 AI 回复（V2.1 规则引擎，V3.0 LLM）
    private func generateResponse(for userText: String) -> String {
        let lower = userText.lowercased()

        // 关键词匹配路由
        if lower.contains("少推") || lower.contains("太多") || lower.contains("减少") {
            return handleReduceFrequency()
        }

        if lower.contains("多推") || lower.contains("不够") || lower.contains("增加") {
            return handleIncreaseFrequency()
        }

        if lower.contains("天气") {
            return handleCategoryToggle("天气", enable: true)
        }

        if lower.contains("健康") || lower.contains("运动") || lower.contains("步数") {
            return handleHealthRequest()
        }

        if lower.contains("不要") && lower.contains("天气") {
            return handleCategoryToggle("天气", enable: false)
        }

        if lower.contains("安静") || lower.contains("别打扰") || lower.contains("免打扰") {
            return handleQuietTime()
        }

        if lower.contains("早安") || lower.contains("早上好") || lower.contains("hello") {
            return "早上好！今天有什么需要我帮忙的吗？你可以说\"少推一点\"或\"多推一些天气提醒\"来调整。"
        }

        if lower.contains("感谢") || lower.contains("谢谢") {
            return "不客气！有什么需要随时说。"
        }

        // 默认回复
        return "我理解了。你可以说以下指令来调整提醒：\n\n• \"少推一点\" — 降低推送频率\n• \"多推一些天气提醒\" — 增加天气类别\n• \"安静时段延长到12点\" — 调整免打扰\n• \"我的运动数据\" — 查看健康信息"
    }

    // MARK: - 处理函数

    private func handleReduceFrequency() -> String {
        let prefs = UserPreferences.load()
        let currentHours = prefs.pushFrequency
        let newHours = min(currentHours + 1, 6)

        var updated = prefs
        updated.pushFrequency = newHours
        updated.save()

        return "好的，推送频率已从每 \(currentHours) 小时调整为每 \(newHours) 小时。如果你觉得还是太多，可以再说一次。"
    }

    private func handleIncreaseFrequency() -> String {
        let prefs = UserPreferences.load()
        let currentHours = prefs.pushFrequency
        let newHours = max(currentHours - 1, 1)

        var updated = prefs
        updated.pushFrequency = newHours
        updated.save()

        return "好的，推送频率已从每 \(currentHours) 小时调整为每 \(newHours) 小时。"
    }

    private func handleCategoryToggle(_ category: String, enable: Bool) -> String {
        let action = enable ? "增加" : "减少"
        // TODO: 更新类别权重
        PreferenceLearner.shared.recordCategoryFeedback(category: category, positive: enable)

        let detail = enable ? "有好的天气/日历提醒时会优先推送。" : "会大幅减少此类推送。"
        return "好的，会\(action)\(category)类提醒的推送。\(detail)"
    }

    private func handleHealthRequest() -> String {
        if SubscriptionManager.shared.currentTier == .free {
            return "健康数据是 Pro 功能。升级 Pro 后可以结合运动、睡眠数据生成提醒。"
        }

        Task {
            await HealthService.shared.fetchAllHealthData()
        }

        return "正在获取你的健康数据... 稍等一下就能看到今天的运动和睡眠情况了。"
    }

    private func handleQuietTime() -> String {
        return "你可以在设置页面调整安静时段。目前安静时段是 \(UserPreferences.load().quietTimeStart):00 - \(UserPreferences.load().quietTimeEnd):00。"
    }

    // MARK: - 清除

    func clearMessages() {
        messages.removeAll()
    }
}
