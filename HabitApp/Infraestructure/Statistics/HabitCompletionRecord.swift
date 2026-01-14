#if PREMIUM || PLUGIN_STATS
import Foundation
import SwiftData

@Model
final class HabitCompletionRecord: Identifiable {
    private(set) var id: UUID
    var habitId: UUID
    var date: Date
    var count: Int

    init(habitId: UUID, date: Date, count: Int = 1) {
        self.id = UUID()
        self.habitId = habitId
        self.date = date
        self.count = count
    }
}

#endif
