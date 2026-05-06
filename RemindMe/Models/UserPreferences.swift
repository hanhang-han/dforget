import Foundation

struct UserPreferences: Codable {
    var pushFrequency: Int // 间隔小时数，默认2
    var quietTimeStart: String // "HH:mm"
    var quietTimeEnd: String
    var weatherEnabled: Bool
    var calendarEnabled: Bool
    var hasCompletedOnboarding: Bool

    static let defaultPreferences = UserPreferences(
        pushFrequency: 2,
        quietTimeStart: "23:00",
        quietTimeEnd: "08:00",
        weatherEnabled: true,
        calendarEnabled: true,
        hasCompletedOnboarding: false
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
