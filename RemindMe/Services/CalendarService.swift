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
    func fetchUpcomingEvents(limit: Int = 5) -> [String] {
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
            return "\(time) \(event.title)"
        }
    }
}
