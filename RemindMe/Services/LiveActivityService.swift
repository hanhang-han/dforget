import ActivityKit
import SwiftUI

@MainActor
final class LiveActivityService: ObservableObject {
    static let shared = LiveActivityService()

    @Published var currentActivity: Activity<RemindMeAttributes>?
    @Published var isLiveActivitySupported = ActivityAuthorizationInfo().areActivitiesEnabled

    private init() {}

    func startLiveActivity(reminderText: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // 如果已有一个 Live Activity，先结束它
        endLiveActivity()

        let attributes = RemindMeAttributes()
        let state = RemindMeAttributes.ContentState(
            reminderText: reminderText,
            timestamp: Date()
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil)
            )
            currentActivity = activity
        } catch {
            print("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    func updateLiveActivity(reminderText: String) async {
        guard let activity = currentActivity else {
            startLiveActivity(reminderText: reminderText)
            return
        }

        let state = RemindMeAttributes.ContentState(
            reminderText: reminderText,
            timestamp: Date()
        )

        await activity.update(
            ActivityContent(state: state, staleDate: nil)
        )
    }

    func endLiveActivity() {
        guard let activity = currentActivity else { return }

        let state = RemindMeAttributes.ContentState(
            reminderText: activity.content.state.reminderText,
            timestamp: activity.content.state.timestamp
        )

        Task {
            await activity.end(
                ActivityContent(state: state, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }
        currentActivity = nil
    }
}
