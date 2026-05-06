import Foundation
import SwiftData

@Model
final class ReminderItem {
    var id: UUID
    var text: String
    var category: ReminderCategory
    var timestamp: Date
    var isRead: Bool
    var isSmallNote: Bool
    var feedbackType: String // "none", "positive", "neutral", "negative"

    init(
        id: UUID = UUID(),
        text: String,
        category: ReminderCategory = .general,
        timestamp: Date = .now,
        isRead: Bool = false,
        isSmallNote: Bool = false,
        feedbackType: String = "none"
    ) {
        self.id = id
        self.text = text
        self.category = category
        self.timestamp = timestamp
        self.isRead = isRead
        self.isSmallNote = isSmallNote
        self.feedbackType = feedbackType
    }
}
