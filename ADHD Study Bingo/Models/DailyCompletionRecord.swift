import Foundation
import SwiftData

@Model
final class DailyCompletionRecord: Identifiable {
    var id: UUID
    var task: StudyTask?
    var completedMinutes: Int
    var completedAt: Date
    var dayKey: String

    init(
        id: UUID = UUID(),
        task: StudyTask,
        completedMinutes: Int,
        completedAt: Date,
        dayKey: String = ""
    ) {
        self.id = id
        self.task = task
        self.completedMinutes = completedMinutes
        self.completedAt = completedAt
        self.dayKey = dayKey
    }
}
