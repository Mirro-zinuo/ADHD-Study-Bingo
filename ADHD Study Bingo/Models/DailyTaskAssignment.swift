import Foundation
import SwiftData

@Model
final class DailyTaskAssignment: Identifiable {
    var id: UUID
    var task: StudyTask?
    var plannedMinutes: Int
    var isCompleted: Bool
    var dayKey: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        task: StudyTask,
        plannedMinutes: Int,
        isCompleted: Bool = false,
        dayKey: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.task = task
        self.plannedMinutes = plannedMinutes
        self.isCompleted = isCompleted
        self.dayKey = dayKey
        self.createdAt = createdAt
    }
}
