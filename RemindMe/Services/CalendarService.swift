import EventKit

@MainActor
final class CalendarService: ObservableObject {
    static let shared = CalendarService()

    @Published var isAuthorized = false
    private let store = EKEventStore()

    private init() {}

    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        store.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                completion?(granted)
            }
        }
    }

    func checkAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        isAuthorized = status == .fullAccess
    }

    /// 获取今天和未来事件（简化版，最多返回 5 个）
    func fetchUpcomingEvents(limit: Int = 5) -> [CalendarEvent] {
        guard isAuthorized else { return [] }

        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: .now)
        guard let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) else { return [] }

        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = store.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
            .prefix(limit)

        return events.map { event in
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let time = formatter.string(from: event.startDate)
            return CalendarEvent(
                title: event.title,
                time: time,
                start: event.startDate,
                end: event.endDate,
                location: event.location,
                notes: event.notes,
                isAllDay: event.isAllDay
            )
        }
    }

    // MARK: - V2.1 高级日历联动

    /// 获取即将到来的事件（1小时内）
    func fetchEventsWithinOneHour() -> [CalendarEvent] {
        guard isAuthorized else { return [] }

        let now = Date()
        guard let oneHourLater = Calendar.current.date(byAdding: .hour, value: 1, to: now) else { return [] }

        let predicate = store.predicateForEvents(withStart: now, end: oneHourLater, calendars: nil)
        let events = store.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }

        return events.map { event in
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return CalendarEvent(
                title: event.title,
                time: formatter.string(from: event.startDate),
                start: event.startDate,
                end: event.endDate,
                location: event.location,
                notes: event.notes,
                isAllDay: event.isAllDay
            )
        }
    }

    /// 检查是否有密集会议（连续3+个会议）
    func hasBackToBackMeetings() -> Bool {
        let events = fetchUpcomingEvents(limit: 10)
        var consecutiveCount = 0

        for event in events {
            if event.title.lowercased().contains("会议") ||
               event.title.lowercased().contains("meeting") ||
               event.title.lowercased().contains("1v1") ||
               event.title.lowercased().contains("周会") {
                consecutiveCount += 1
            } else {
                consecutiveCount = 0
            }
        }

        return consecutiveCount >= 3
    }

    /// 获取今日会议总数
    func todayMeetingCount() -> Int {
        let events = fetchUpcomingEvents(limit: 20)
        return events.filter { event in
            let lower = event.title.lowercased()
            return lower.contains("会议") || lower.contains("meeting") || lower.contains("1v1") || lower.contains("周会")
        }.count
    }

    /// 生成日历相关提醒文案
    func generateCalendarReminders() -> [String] {
        var reminders: [String] = []

        let upcoming = fetchEventsWithinOneHour()
        if !upcoming.isEmpty {
            let event = upcoming[0]
            if event.location != nil {
                reminders.append("一小时后有「\(event.title)」，地点是 \(event.location ?? "")")
            } else {
                reminders.append("一小时后有「\(event.title)」，别忘了提前准备")
            }
        }

        if hasBackToBackMeetings() {
            reminders.append("今天会议很多，记得合理安排休息时间")
        }

        let meetingCount = todayMeetingCount()
        if meetingCount >= 5 {
            reminders.append("今天有 \(meetingCount) 个会议，适当放松")
        }

        return reminders
    }
}

// MARK: - 日历事件模型

struct CalendarEvent {
    let title: String
    let time: String
    let start: Date
    let end: Date
    let location: String?
    let notes: String?
    let isAllDay: Bool
}
