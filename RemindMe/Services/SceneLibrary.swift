// V1.1 — 生活提醒场景库
// 覆盖全天 8 个时段、8 个类别，50+ 场景
// 每次 10 分钟轮换从中选取，同一天不重复

import Foundation

// MARK: - 时段定义

enum TimeSlot: Int, CaseIterable {
    case earlyMorning = 0   // 6-9   早起出门
    case morning = 1        // 9-12  上午工作
    case noon = 2           // 12-14 午间休息
    case afternoon = 3      // 14-17 下午工作
    case lateAfternoon = 4  // 17-19 傍晚下班
    case evening = 5        // 19-22 晚间居家
    case night = 6          // 22+   深夜
    case weekend = 7        // 周末全天

    /// 根据当前时间和是否周末返回对应时段
    static func current() -> TimeSlot {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)

        // 周六日
        if weekday == 1 || weekday == 7 {
            return .weekend
        }

        switch hour {
        case 0..<6:  return .night
        case 6..<9:  return .earlyMorning
        case 9..<12: return .morning
        case 12..<14: return .noon
        case 14..<17: return .afternoon
        case 17..<19: return .lateAfternoon
        case 19..<22: return .evening
        default:     return .night
        }
    }
}

// MARK: - 场景优先级

enum ScenePriority: Int {
    case high = 3
    case medium = 2
    case low = 1
}

// MARK: - 场景定义

struct ReminderScene {
    let id: String
    let text: String
    let category: ReminderCategory
    let timeSlots: [TimeSlot]
    let priority: ScenePriority
    let requiresWeather: Bool
    let requiresCalendar: Bool
    let isSmallNote: Bool

    init(
        id: String,
        text: String,
        category: ReminderCategory = .general,
        timeSlots: [TimeSlot],
        priority: ScenePriority = .medium,
        requiresWeather: Bool = false,
        requiresCalendar: Bool = false,
        isSmallNote: Bool = false
    ) {
        self.id = id
        self.text = text
        self.category = category
        self.timeSlots = timeSlots
        self.priority = priority
        self.requiresWeather = requiresWeather
        self.requiresCalendar = requiresCalendar
        self.isSmallNote = isSmallNote
    }
}

// MARK: - 场景库

struct SceneLibrary {
    static let shared = SceneLibrary()

    let scenes: [ReminderScene]

    private init() {
        scenes = Self.allScenes
    }

    // MARK: - 适合当前时段的候选场景

    func candidates(for slot: TimeSlot, seenToday: Set<String>) -> [ReminderScene] {
        scenes.filter { scene in
            // 时段匹配
            scene.timeSlots.contains(slot) &&
            // 今天没出现过
            !seenToday.contains(scene.id)
        }
    }

    // MARK: - 全量场景定义

    private static let allScenes: [ReminderScene] = [
        // ===== A. 早起出门 (earlyMorning) =====

        ReminderScene(id: "em_umbrella", text: "今天有雨，出门记得带伞，伞在玄关鞋柜旁边。",
              category: .weather, timeSlots: [.earlyMorning], priority: .high, requiresWeather: true),

        ReminderScene(id: "em_cold", text: "今天比昨天冷了不少，出门加件外套吧，别逞强。",
              category: .weather, timeSlots: [.earlyMorning], priority: .high, requiresWeather: true),

        ReminderScene(id: "em_sunscreen", text: "今天紫外线很强，涂个防晒再出门。",
              category: .weather, timeSlots: [.earlyMorning, .morning], priority: .medium, requiresWeather: true),

        ReminderScene(id: "em_keys", text: "出门前确认一下：钥匙、工牌、充电器都带了吗？",
              category: .time, timeSlots: [.earlyMorning], priority: .medium),

        ReminderScene(id: "em_trash", text: "今天是倒垃圾日，出门顺手带下去吧。",
              category: .time, timeSlots: [.earlyMorning], priority: .medium),

        ReminderScene(id: "em_breakfast", text: "早饭吃了吗？空腹上班容易低血糖。",
              category: .time, timeSlots: [.earlyMorning], priority: .medium),

        ReminderScene(id: "em_charge_full", text: "手机电充满了，出门前可以拔掉充电器了。",
              category: .time, timeSlots: [.earlyMorning], priority: .low),

        ReminderScene(id: "em_medicine", text: "早上的药吃了吗？别因为赶时间就跳过。",
              category: .time, timeSlots: [.earlyMorning], priority: .high),

        // ===== B. 上午工作 (morning) =====

        ReminderScene(id: "mo_sit", text: "坐了一个多小时了，站起来接杯水吧。",
              category: .time, timeSlots: [.morning, .afternoon], priority: .medium),

        ReminderScene(id: "mo_eyes", text: "看了好久屏幕了，看看窗外，让眼睛休息一分钟。",
              category: .time, timeSlots: [.morning, .afternoon], priority: .medium),

        ReminderScene(id: "mo_water", text: "喝口水吧，上午过了一半了，别忙得忘了喝水。",
              category: .time, timeSlots: [.morning], priority: .medium),

        ReminderScene(id: "mo_priority", text: "上午过半了，今天的重点任务开始了吗？",
              category: .time, timeSlots: [.morning], priority: .medium),

        ReminderScene(id: "mo_meeting_prep", text: "过一会儿有会，材料准备好了吗？提前看一看。",
              category: .calendar, timeSlots: [.morning, .afternoon], priority: .high, requiresCalendar: true),

        ReminderScene(id: "mo_focus", text: "上午是精力最好的时候，趁现在把最难的事做了。",
              category: .time, timeSlots: [.morning], priority: .low),

        ReminderScene(id: "mo_breathe", text: "做几个深呼吸，缓解一下上午的紧张感。",
              category: .general, timeSlots: [.morning, .afternoon], priority: .low),

        // ===== C. 午间休息 (noon) =====

        ReminderScene(id: "no_lunch", text: "午饭吃了没？再忙也要吃饭，你的胃在抗议了。",
              category: .time, timeSlots: [.noon], priority: .medium),

        ReminderScene(id: "no_package", text: "快递柜里有你的包裹，中午抽空取一下吧。",
              category: .time, timeSlots: [.noon, .evening], priority: .medium),

        ReminderScene(id: "no_nap", text: "午休别睡太久，20-30 分钟刚好，定个闹钟吧。",
              category: .time, timeSlots: [.noon], priority: .low),

        ReminderScene(id: "no_walk", text: "吃完饭散个步吧，别直接趴在桌上睡了。",
              category: .time, timeSlots: [.noon], priority: .low),

        ReminderScene(id: "no_afternoon_meeting", text: "下午 1:30 那个会别忘了，设好闹钟了吗？",
              category: .calendar, timeSlots: [.noon], priority: .high, requiresCalendar: true),

        // ===== D. 下午工作 (afternoon) =====

        ReminderScene(id: "af_water", text: "喝口水吧，今天喝够 8 杯了吗？",
              category: .time, timeSlots: [.afternoon], priority: .medium),

        ReminderScene(id: "af_stand", text: "又坐了两小时了，你的腰会感谢你站一会的。",
              category: .time, timeSlots: [.afternoon], priority: .medium),

        ReminderScene(id: "af_sleepy", text: "下午容易犯困，站起来走走或者洗把脸。",
              category: .time, timeSlots: [.afternoon], priority: .low),

        ReminderScene(id: "af_meetings_dense", text: "今天会议很密集，趁现在这段空闲去倒杯水。",
              category: .calendar, timeSlots: [.afternoon], priority: .high, requiresCalendar: true),

        ReminderScene(id: "af_bill", text: "这个月的账单该交了，趁现在有空处理一下？",
              category: .time, timeSlots: [.afternoon], priority: .medium),

        ReminderScene(id: "af_grocery", text: "今天要买菜吗？叮咚截单前下好单到家刚好。",
              category: .time, timeSlots: [.afternoon, .lateAfternoon], priority: .low),

        ReminderScene(id: "af_battery", text: "手机电量不多了，趁在工座充一下吧。",
              category: .time, timeSlots: [.afternoon, .lateAfternoon], priority: .medium),

        ReminderScene(id: "af_snack", text: "下午三四点了，吃点小零食补充一下能量？",
              category: .time, timeSlots: [.afternoon], priority: .low),

        // ===== E. 傍晚下班 (lateAfternoon) =====

        ReminderScene(id: "la_clock", text: "准备下班了？别忘了打卡。",
              category: .time, timeSlots: [.lateAfternoon], priority: .high),

        ReminderScene(id: "la_summary", text: "今天的工作收个尾，明天的重点先记下来。",
              category: .time, timeSlots: [.lateAfternoon], priority: .medium),

        ReminderScene(id: "la_belongings", text: "离开前检查一下：充电器、耳机、U盘都收好了吗？",
              category: .time, timeSlots: [.lateAfternoon], priority: .medium),

        ReminderScene(id: "la_fruit", text: "下班路上顺路买点水果？小区门口那家挺新鲜的。",
              category: .time, timeSlots: [.lateAfternoon], priority: .low),

        ReminderScene(id: "la_package", text: "楼下有你的快递，下班顺手拿了再走吧。",
              category: .time, timeSlots: [.lateAfternoon], priority: .medium),

        ReminderScene(id: "la_rain", text: "外面在下雨，带伞了吗？没有的话等等再走。",
              category: .weather, timeSlots: [.lateAfternoon], priority: .high, requiresWeather: true),

        ReminderScene(id: "la_safe", text: "下班路上注意安全，不着急，慢慢来。",
              category: .time, timeSlots: [.lateAfternoon], priority: .low),

        ReminderScene(id: "la_friday", text: "周五了！周末有什么计划吗？提前想好才不会浪费。",
              category: .time, timeSlots: [.lateAfternoon], priority: .low),

        // ===== F. 晚间居家 (evening) =====

        ReminderScene(id: "ev_rest", text: "到家了先歇一会儿，辛苦一天了。",
              category: .time, timeSlots: [.evening], priority: .low),

        ReminderScene(id: "ev_dinner", text: "晚饭想好吃什么了吗？冰箱里看看还有什么。",
              category: .time, timeSlots: [.evening], priority: .medium),

        ReminderScene(id: "ev_charge", text: "电动车该充电了，明天还要骑呢。",
              category: .time, timeSlots: [.evening], priority: .medium),

        ReminderScene(id: "ev_call_home", text: "给家里打个电话吧，好久没聊了。",
              category: .general, timeSlots: [.evening], priority: .low, isSmallNote: true),

        ReminderScene(id: "ev_medicine_night", text: "晚上的药吃了吗？别等到睡前才想起来。",
              category: .time, timeSlots: [.evening], priority: .high),

        ReminderScene(id: "ev_trash_night", text: "睡前垃圾记得带下去，不然明天该有味道了。",
              category: .time, timeSlots: [.evening], priority: .low),

        ReminderScene(id: "ev_tomorrow", text: "明天要带什么？趁现在准备好比早上不慌。",
              category: .time, timeSlots: [.evening], priority: .medium),

        ReminderScene(id: "ev_cold_tomorrow", text: "明天降温明显，睡前把厚衣服拿出来。",
              category: .weather, timeSlots: [.evening], priority: .high, requiresWeather: true),

        ReminderScene(id: "ev_tomorrow_early", text: "明天有早会，闹钟设好了吗？今晚早点睡。",
              category: .calendar, timeSlots: [.evening], priority: .high, requiresCalendar: true),

        ReminderScene(id: "ev_phone_charge", text: "手机充上电吧，明天还要满电出发。",
              category: .time, timeSlots: [.evening], priority: .medium),

        ReminderScene(id: "ev_walk_dog", text: "毛孩子等你一天了，出去溜一圈吧。",
              category: .general, timeSlots: [.evening], priority: .medium),

        ReminderScene(id: "ev_water_plant", text: "绿萝好像有点蔫了，给它浇点水吧。",
              category: .general, timeSlots: [.evening, .weekend], priority: .low),

        // ===== G. 深夜 (night) =====

        ReminderScene(id: "nt_sleep", text: "夜深了，放下手机吧。明天的事明天再说。",
              category: .general, timeSlots: [.night], priority: .high),

        ReminderScene(id: "nt_screen", text: "你已经连续看屏幕很久了，你的眼睛和颈椎都需要休息。",
              category: .time, timeSlots: [.night], priority: .medium),

        ReminderScene(id: "nt_peace", text: "今天结束了，不管好坏都过去了。好好睡一觉。",
              category: .general, timeSlots: [.night], priority: .low, isSmallNote: true),

        // ===== H. 周末 (weekend) =====

        ReminderScene(id: "we_weather", text: "周末天气不错，出去走走？公园应该很舒服。",
              category: .weather, timeSlots: [.weekend], priority: .medium, requiresWeather: true),

        ReminderScene(id: "we_cook", text: "周末了，给自己做顿好吃的吧，平时都凑合。",
              category: .general, timeSlots: [.weekend], priority: .low),

        ReminderScene(id: "we_laundry", text: "该洗的衣服堆了不少了吧？趁着周末天气好洗了。",
              category: .time, timeSlots: [.weekend], priority: .medium),

        ReminderScene(id: "we_clean", text: "两周没打扫了，趁着周末简单收拾一下？",
              category: .time, timeSlots: [.weekend], priority: .low),

        ReminderScene(id: "we_friend", text: "好久没约朋友了，这周末要不要见个面？",
              category: .general, timeSlots: [.weekend], priority: .low, isSmallNote: true),

        ReminderScene(id: "we_hobby", text: "周末了，做点自己喜欢的事吧，别全用来补觉了。",
              category: .general, timeSlots: [.weekend], priority: .low),

        ReminderScene(id: "we_sleep", text: "周末也别睡太晚，作息乱了周一更难受。",
              category: .time, timeSlots: [.weekend], priority: .low),

        // ===== I. 小纸条（情感类，全天候） =====

        ReminderScene(id: "note_encourage", text: "你今天做得很好，继续加油。",
              category: .general, timeSlots: [.morning, .afternoon], priority: .low, isSmallNote: true),

        ReminderScene(id: "note_slow", text: "生活不是比赛，偶尔慢下来也没关系。",
              category: .general, timeSlots: [.morning, .afternoon, .evening], priority: .low, isSmallNote: true),

        ReminderScene(id: "note_small_joy", text: "今天有什么值得开心的小事吗？停下来想想。",
              category: .general, timeSlots: [.afternoon, .evening], priority: .low, isSmallNote: true),

        ReminderScene(id: "note_kind", text: "试着对身边的人说一句谢谢，你会发现心情变好。",
              category: .general, timeSlots: [.morning, .afternoon], priority: .low, isSmallNote: true),

        ReminderScene(id: "note_effort", text: "你已经很努力了，不要对自己太苛刻。",
              category: .general, timeSlots: [.afternoon, .evening], priority: .low, isSmallNote: true),

        ReminderScene(id: "note_coffee", text: "给自己买杯好喝的吧，犒劳一下辛苦的自己。",
              category: .general, timeSlots: [.morning, .afternoon], priority: .low, isSmallNote: true),

        ReminderScene(id: "note_smile", text: "你笑起来的样子比你想的要好看。",
              category: .general, timeSlots: [.morning, .noon], priority: .low, isSmallNote: true),
    ]
}
