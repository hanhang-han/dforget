import Foundation

/// V3.0: 高级提醒类别
/// 家庭、宠物、财务、学习、社交等 Pro 独占类别
/// TODO: AI Integration — 每个类别需要专门的 LLM prompt 模板

enum AdvancedCategory: String, CaseIterable, Codable {
    case family = "家庭"
    case pet = "宠物"
    case finance = "财务"
    case study = "学习"
    case social = "社交"

    var iconName: String {
        switch self {
        case .family: return "house.fill"
        case .pet: return "pawprint.fill"
        case .finance: return "creditcard.fill"
        case .study: return "book.fill"
        case .social: return "person.2.fill"
        }
    }

    var description: String {
        switch self {
        case .family: return "家庭纪念日、家务提醒、家人关怀"
        case .pet: return "喂食、遛狗、疫苗、洗澡"
        case .finance: return "账单还款、记账提醒、预算控制"
        case .study: return "学习打卡、阅读提醒、课程安排"
        case .social: return "生日祝福、节日问候、回复消息"
        }
    }

    var sampleReminders: [String] {
        switch self {
        case .family:
            return [
                "今天是爸妈的结婚纪念日，打个电话",
                "冰箱里的菜快过期了，记得处理",
                "下周是孩子的家长会，提前安排时间",
                "该给家里打个电话了",
            ]
        case .pet:
            return [
                "该给 \\(PetProfileManager.shared.currentPet?.name ?? \"毛孩子\") 喂食了",
                "今天天气好，带 \\(PetProfileManager.shared.currentPet?.name ?? \"它\") 出去走走",
                "距离上次驱虫已经 30 天了，该安排了",
                "记得给 \\(PetProfileManager.shared.currentPet?.name ?? \"它\") 补充饮水",
            ]
        case .finance:
            return [
                "信用卡账单明天到期，记得还",
                "本月预算已使用 80%，注意控制",
                "今天是发薪日，别忘了查看工资",
                "水电费该缴了，避免逾期",
            ]
        case .study:
            return [
                "今天的学习计划完成了吗？",
                "上次读到第 3 章，继续吧",
                "课程作业明天截止",
                "坚持了 7 天连续学习，很棒",
            ]
        case .social:
            return [
                "今天是朋友的生日，发个祝福",
                "好久没联系 \\(SocialReminderEngine.randomContact()) 了，聊聊",
                "上次的聚会照片整理了吗？",
                "周末约朋友出来聚聚？",
            ]
        }
    }
}

// MARK: - 宠物档案管理

final class PetProfileManager: ObservableObject {
    static let shared = PetProfileManager()

    struct PetProfile: Codable {
        var name: String
        var type: PetType
        var feedInterval: Int  // 小时
        var walkInterval: Int  // 小时
        var lastFed: Date?
        var lastWalked: Date?
        var lastDeworming: Date?
        var birthday: Date?
    }

    enum PetType: String, Codable {
        case dog = "狗"
        case cat = "猫"
        case other = "其他"
    }

    @Published var currentPet: PetProfile?

    private let defaults = UserDefaults.standard

    func savePet(_ pet: PetProfile) {
        currentPet = pet
        if let data = try? JSONEncoder().encode(pet) {
            defaults.set(data, forKey: "pet_profile")
        }
    }

    func loadPet() {
        guard let data = defaults.data(forKey: "pet_profile") else { return }
        currentPet = try? JSONDecoder().decode(PetProfile.self, from: data)
    }

    /// 生成宠物相关提醒
    func generatePetReminders() -> [String] {
        guard let pet = currentPet else { return [] }

        var reminders: [String] = []

        if let lastFed = pet.lastFed {
            let hours = Calendar.current.dateComponents([.hour], from: lastFed, to: Date()).hour ?? 0
            if hours >= pet.feedInterval {
                reminders.append("该给 \\(pet.name) 喂食了")
            }
        }

        if let lastWalked = pet.lastWalked, pet.type == .dog {
            let hours = Calendar.current.dateComponents([.hour], from: lastWalked, to: Date()).hour ?? 0
            if hours >= pet.walkInterval {
                reminders.append("该带 \\(pet.name) 出去遛遛了")
            }
        }

        if let lastDeworming = pet.lastDeworming {
            let days = Calendar.current.dateComponents([.day], from: lastDeworming, to: Date()).day ?? 0
            if days >= 30 {
                reminders.append("\\(pet.name) 距离上次驱虫已经 \\(days) 天了")
            }
        }

        if let birthday = pet.birthday {
            let components = Calendar.current.dateComponents([.month, .day], from: birthday, to: Date())
            if components.month == 0 && components.day == 0 {
                reminders.append("今天是 \\(pet.name) 的生日！")
            }
        }

        return reminders
    }
}

// MARK: - 社交提醒引擎

final class SocialReminderEngine {
    static let shared = SocialReminderEngine()

    /// 随机联系人名称（V3.0 伪数据）
    static func randomContact() -> String {
        ["小明", "小红", "老王", "小李", "阿杰", "小美"][Int.random(in: 0..<6)]
    }

    /// 检查是否有生日/纪念日
    /// TODO: 从通讯录读取
    func checkUpcomingBirthdays() -> [String] {
        // V3.0 伪数据
        return []
    }
}
