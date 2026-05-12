import Foundation

// V1.1 — 用户偏好（新增每日上限 + 时段开关 + 音效）
struct UserPreferences: Codable {
    var pushFrequency: Int // 间隔小时数，默认2
    var quietTimeStart: String // "HH:mm"
    var quietTimeEnd: String
    var weatherEnabled: Bool
    var calendarEnabled: Bool
    var hasCompletedOnboarding: Bool

    // V1.1 新增
    var dailyLimit: Int                        // 每天上限，默认 5
    var timeSlotToggles: TimeSlotToggles       // 分段时段开关
    var soundType: SoundType                   // 音效选择

    struct TimeSlotToggles: Codable {
        var morning: Bool    // 07-09
        var forenoon: Bool   // 09-12
        var midday: Bool     // 12-14
        var afternoon: Bool  // 14-18
        var evening: Bool    // 18-22

        static let allOn = TimeSlotToggles(morning: true, forenoon: true, midday: true, afternoon: true, evening: true)
    }

    enum SoundType: String, Codable, CaseIterable {
        case gentle = "gentle"     // 柔和叮
        case urgent = "urgent"     // 紧急叮叮
        case silent = "silent"     // 静默

        var displayName: String {
            switch self {
            case .gentle: return "柔和叮"
            case .urgent: return "紧急叮叮"
            case .silent: return "静默"
            }
        }
    }

    static let defaultPreferences = UserPreferences(
        pushFrequency: 2,
        quietTimeStart: "23:00",
        quietTimeEnd: "08:00",
        weatherEnabled: true,
        calendarEnabled: true,
        hasCompletedOnboarding: false,
        dailyLimit: 5,
        timeSlotToggles: .allOn,
        soundType: .gentle
    )

    static func load() -> UserPreferences {
        if let data = UserDefaults.standard.data(forKey: "userPreferences"),
           let prefs = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            return prefs
        }
        return .defaultPreferences
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "userPreferences")
        }
    }

    var pushIntervalSeconds: TimeInterval {
        TimeInterval(pushFrequency) * 3600
    }
}
