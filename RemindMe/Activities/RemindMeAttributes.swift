import ActivityKit
import WidgetKit
import SwiftUI

struct RemindMeAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var reminderText: String
        var timestamp: Date
    }
    // 无固定属性，所有动态数据通过 ContentState 传递
}
