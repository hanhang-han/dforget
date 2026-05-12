// V1.1 — 设置 ViewModel（新增每日上限 + 时段 + 音效）
import Foundation
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var pushFrequency: Int
    @Published var quietTimeStart: Date
    @Published var quietTimeEnd: Date
    @Published var weatherEnabled: Bool
    @Published var calendarEnabled: Bool
    @Published var notificationAuthorized: Bool
    @Published var calendarAuthorized: Bool

    // V1.1 新增
    @Published var dailyLimit: Int
    @Published var timeSlotToggles: UserPreferences.TimeSlotToggles
    @Published var soundType: UserPreferences.SoundType

    private let notificationService = NotificationService.shared
    private let calendarService = CalendarService.shared

    init() {
        let prefs = UserPreferences.load()

        self.pushFrequency = prefs.pushFrequency
        self.weatherEnabled = prefs.weatherEnabled
        self.calendarEnabled = prefs.calendarEnabled

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        self.quietTimeStart = formatter.date(from: prefs.quietTimeStart) ?? Date()
        self.quietTimeEnd = formatter.date(from: prefs.quietTimeEnd) ?? Date()

        self.notificationAuthorized = notificationService.isAuthorized
        self.calendarAuthorized = calendarService.isAuthorized

        // V1.1
        self.dailyLimit = prefs.dailyLimit
        self.timeSlotToggles = prefs.timeSlotToggles
        self.soundType = prefs.soundType
    }

    func save() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        var prefs = UserPreferences.load()
        prefs.pushFrequency = pushFrequency
        prefs.quietTimeStart = formatter.string(from: quietTimeStart)
        prefs.quietTimeEnd = formatter.string(from: quietTimeEnd)
        prefs.weatherEnabled = weatherEnabled
        prefs.calendarEnabled = calendarEnabled
        prefs.dailyLimit = dailyLimit
        prefs.timeSlotToggles = timeSlotToggles
        prefs.soundType = soundType
        prefs.save()
    }

    func requestNotificationPermission() {
        notificationService.requestAuthorization { granted in
            self.notificationAuthorized = granted
        }
    }

    func requestCalendarPermission() {
        calendarService.requestAuthorization { granted in
            self.calendarAuthorized = granted
        }
    }

    var quietTimeStartString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: quietTimeStart)
    }

    var quietTimeEndString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: quietTimeEnd)
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}
