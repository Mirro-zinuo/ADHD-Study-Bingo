import Foundation
import SwiftData

@Model
final class StudyTask: Identifiable {
    var id: UUID
    var title: String
    var totalMinutes: Int
    var completedMinutes: Int
    var daysLeft: Int
    var deadlineDate: Date
    var initialDays: Int
    var dailyTargetMinutes: Double

    @Relationship(deleteRule: .cascade, inverse: \DailyTaskAssignment.task)
    var dailyAssignments: [DailyTaskAssignment] = []

    @Relationship(deleteRule: .cascade, inverse: \DailyCompletionRecord.task)
    var completionRecords: [DailyCompletionRecord] = []

    init(
        id: UUID = UUID(),
        title: String,
        totalMinutes: Int,
        completedMinutes: Int = 0,
        deadlineDate: Date,
        today: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.totalMinutes = totalMinutes
        self.completedMinutes = completedMinutes
        self.deadlineDate = deadlineDate

        let calculatedDays = Self.daysLeft(from: today, to: deadlineDate)
        self.daysLeft = calculatedDays
        self.initialDays = calculatedDays

        let remaining = max(totalMinutes - completedMinutes, 0)
        self.dailyTargetMinutes = Double(remaining) / Double(max(calculatedDays, 1))
    }

    var remainingMinutes: Int {
        max(totalMinutes - completedMinutes, 0)
    }

    var completedProgress: Double {
        guard totalMinutes > 0 else { return 0 }
        return min(max(Double(completedMinutes) / Double(totalMinutes), 0), 1)
    }

    var remainingProgress: Double {
        guard totalMinutes > 0 else { return 0 }
        return min(max(Double(remainingMinutes) / Double(totalMinutes), 0), 1)
    }

    private static func daysLeft(from today: Date, to deadline: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: today)
        let end = calendar.startOfDay(for: deadline)
        let diff = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(diff + 1, 1)
    }
}
