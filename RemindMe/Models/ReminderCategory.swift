import Foundation

enum ReminderCategory: String, Codable, CaseIterable, Identifiable {
    case weather
    case calendar
    case time
    case general

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weather: return "天气"
        case .calendar: return "日历"
        case .time: return "时间"
        case .general: return "日常"
        }
    }

    var iconName: String {
        switch self {
        case .weather: return "cloud.sun"
        case .calendar: return "calendar"
        case .time: return "clock"
        case .general: return "bell"
        }
    }
}
