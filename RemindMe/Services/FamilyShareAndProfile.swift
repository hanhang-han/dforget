import Foundation

/// V3.0: 家庭共享
/// 支持家庭成员之间共享提醒和关怀卡片
/// TODO: 需要后端 iCloud 同步或自定义同步方案

import SwiftData

@Model
final class FamilyMember {
    var id: UUID
    var name: String
    var relation: String       // 配偶、父母、孩子等
    var avatarData: Data?
    var isEnabled: Bool
    var joinDate: Date
    var iCloudDeviceId: String?

    init(name: String, relation: String) {
        self.id = UUID()
        self.name = name
        self.relation = relation
        self.isEnabled = true
        self.joinDate = Date()
    }
}

/// 家庭共享管理器
@MainActor
final class FamilyShareManager: ObservableObject {
    static let shared = FamilyShareManager()

    @Published var members: [FamilyMember] = []
    @Published var sharedReminders: [SharedReminder] = []

    // MARK: - 共享提醒

    @Model
    final class SharedReminder: Identifiable {
        var id: UUID
        var fromMemberId: UUID
        var fromName: String
        var text: String
        var category: String
        var timestamp: Date
        var isRead: Bool

        init(fromMemberId: UUID, fromName: String, text: String, category: String) {
            self.id = UUID()
            self.fromMemberId = fromMemberId
            self.fromName = fromName
            self.text = text
            self.category = category
            self.timestamp = Date()
            self.isRead = false
        }
    }

    // MARK: - 操作

    /// 添加家庭成员
    func addMember(name: String, relation: String, context: ModelContext) {
        let member = FamilyMember(name: name, relation: relation)
        context.insert(member)

        do {
            try context.save()
            members.append(member)
        } catch {
            print("[FamilyShare] Failed to add member: \(error)")
        }
    }

    /// 发送关怀卡片给家庭成员
    /// TODO: 实现跨设备同步
    func sendCareCard(to member: FamilyMember, text: String, context: ModelContext) {
        let reminder = SharedReminder(
            fromMemberId: UUID(), // 当前用户 ID
            fromName: "我",
            text: text,
            category: "care"
        )
        context.insert(reminder)

        do {
            try context.save()
        } catch {
            print("[FamilyShare] Failed to send care card: \(error)")
        }

        // TODO: 通过 iCloud CloudKit 同步到对方设备
    }

    /// 加载家庭成员列表
    func loadMembers(context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<FamilyMember>()
            members = try context.fetch(descriptor)
        } catch {
            print("[FamilyShare] Failed to load members: \(error)")
        }
    }
}

// MARK: - 深度学习个性化

/// V3.0: 用户画像引擎
/// 综合所有数据源构建用户画像，用于精准推荐
/// TODO: AI Integration — 使用 LLM 分析用户画像生成超个性化文案

final class UserProfileEngine {
    static let shared = UserProfileEngine()

    private let defaults = UserDefaults.standard

    // MARK: - 用户画像

    struct UserProfile {
        var lifestyle: LifestyleType
        var activeHours: [Int]        // 活跃时段
        var preferredCategories: [String: Double]
        var sensitivityLevel: Double  // 0-1, 提醒敏感度
        var responsePattern: ResponsePattern

        enum LifestyleType: String {
            case office = "上班族"
            case student = "学生"
            case freelancer = "自由职业"
            case remote = "远程办公"
            case unknown = "未知"
        }

        enum ResponsePattern: String {
            case quickResponder = "快速响应"
            case delayedResponder = "延迟响应"
            case silentReader = "沉默阅读"
            case inactive = "不活跃"
        }
    }

    // MARK: - 构建画像

    /// 基于使用数据构建用户画像
    func buildProfile() -> UserProfile {
        // 活跃时段
        let learner = PreferenceLearner.shared
        let activeHours = learner.getTopActiveHours(limit: 6)

        // 偏好类别
        let sortedCategories = learner.getSortedCategories()
        var preferredCategories: [String: Double] = [:]
        for item in sortedCategories {
            preferredCategories[item.category] = item.score
        }

        // 生活方式推断
        let lifestyle = inferLifestyle(activeHours: activeHours)

        // 响应模式
        let responsePattern = inferResponsePattern()

        // 敏感度
        let sensitivity = max(0, min(1, learner.signalValue))

        return UserProfile(
            lifestyle: lifestyle,
            activeHours: activeHours,
            preferredCategories: preferredCategories,
            sensitivityLevel: sensitivity,
            responsePattern: responsePattern
        )
    }

    private func inferLifestyle(activeHours: [Int]) -> UserProfile.LifestyleType {
        // 简单推断
        if activeHours.contains(9) && activeHours.contains(10) && activeHours.contains(14) {
            return .office
        }
        if activeHours.contains(22) || activeHours.contains(23) {
            return .student
        }
        return .unknown
    }

    private func inferResponsePattern() -> UserProfile.ResponsePattern {
        // TODO: 根据反馈时间和推送时间的差值推断
        return .silentReader
    }

    /// 生成超个性化提醒
    /// TODO: AI Integration — 将用户画像注入 LLM prompt
    func generatePersonalizedReminder() -> String {
        let profile = buildProfile()

        // V3.0 伪代码
        switch profile.lifestyle {
        case .office:
            let officeReminders = [
                "下午 3 点了，起来倒杯水",
                "今天开会多，记得保持水分",
                "工作节奏不错，但也别忘了休息",
            ]
            return officeReminders.randomElement()!

        case .student:
            let studentReminders = [
                "学习了 2 小时，休息 10 分钟",
                "今天的阅读计划完成了吗？",
                "保持专注，但也别忘了吃饭",
            ]
            return studentReminders.randomElement()!

        default:
            let defaultReminders = [
                "今天过得怎么样？",
                "有空的话出去走走吧",
                "别忘了给自己留点放松时间",
            ]
            return defaultReminders.randomElement()!
        }
    }
}
