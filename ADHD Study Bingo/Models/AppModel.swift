import Foundation
import Observation
import SwiftData

@Observable
final class AppModel {
    let modelContext: ModelContext
    var selectedDate: Date
    var hasBingoLine: Bool
    var bingoLineCount: Int
    var showBingoPopup: Bool
    var confettiBurstID: Int
    var bingoFeedbackText: String
    private var feedbackTick: Int

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.selectedDate = Calendar.current.startOfDay(for: Date())
        self.hasBingoLine = false
        self.bingoLineCount = 0
        self.showBingoPopup = false
        self.confettiBurstID = 0
        self.bingoFeedbackText = "⚡ Keep the rhythm! Tap a tile to check in."
        self.feedbackTick = 0
    }

    func calculateDaysLeft(from today: Date, to deadline: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: today)
        let end = calendar.startOfDay(for: deadline)
        let diff = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(diff + 1, 1)
    }

    // Core procedure for AP CSP.
    // Formula: Daily Target = (Total - Completed) / Days Left
    func recalculatePlan(
        tasks: [StudyTask],
        todayActualMinutes: Int,
        focusedTaskID: UUID?,
        currentDate: Date = Date()
    ) -> [StudyTask] {

        for index in tasks.indices {
            tasks[index].daysLeft = calculateDaysLeft(from: currentDate, to: tasks[index].deadlineDate)
        }

        if let focusedTaskID,
            let index = tasks.firstIndex(where: { $0.id == focusedTaskID })
        {
            let safeMinutes = max(todayActualMinutes, 0)
            tasks[index].completedMinutes = min(
                tasks[index].completedMinutes + safeMinutes,
                tasks[index].totalMinutes
            )
        }

        for index in tasks.indices {
            let remaining = max(tasks[index].totalMinutes - tasks[index].completedMinutes, 0)
            if remaining == 0 {
                tasks[index].dailyTargetMinutes = 0
            } else {
                tasks[index].dailyTargetMinutes = Double(remaining) / Double(max(tasks[index].daysLeft, 1))
            }
        }

        return tasks
    }

    func urgencyScore(for task: StudyTask) -> Double {
        let remainingRatio = Double(task.remainingMinutes) / Double(max(task.totalMinutes, 1))
        return task.dailyTargetMinutes * (1 + remainingRatio)
    }

    func sortByUrgency(_ tasks: [StudyTask]) -> [StudyTask] {
        tasks.sorted { urgencyScore(for: $0) > urgencyScore(for: $1) }
    }

    func urgencyLevel(for task: StudyTask) -> UrgencyLevel {
        if task.dailyTargetMinutes >= 60 { return .red }
        if task.dailyTargetMinutes >= 30 { return .orange }
        return .green
    }

    func checkBingoWin(board: [[Bool]]) -> Bool {
        guard board.count == 3, board.allSatisfy({ $0.count == 3 }) else {
            return false
        }

        for row in 0..<3 {
            var allTrue = true
            for col in 0..<3 {
                if board[row][col] == false {
                    allTrue = false
                    break
                }
            }
            if allTrue { return true }
        }

        for col in 0..<3 {
            var allTrue = true
            for row in 0..<3 {
                if board[row][col] == false {
                    allTrue = false
                    break
                }
            }
            if allTrue { return true }
        }

        var diagonalAllTrue = true
        for index in 0..<3 {
            if board[index][index] == false {
                diagonalAllTrue = false
                break
            }
        }
        if diagonalAllTrue { return true }

        diagonalAllTrue = true
        for index in 0..<3 {
            if board[index][2 - index] == false {
                diagonalAllTrue = false
                break
            }
        }

        return diagonalAllTrue
    }

    func countBingoLines(board: [[Bool]]) -> Int {
        guard board.count == 3, board.allSatisfy({ $0.count == 3 }) else {
            return 0
        }

        var lines = 0

        for row in 0..<3 {
            var allTrue = true
            for col in 0..<3 {
                if board[row][col] == false {
                    allTrue = false
                    break
                }
            }
            if allTrue { lines += 1 }
        }

        for col in 0..<3 {
            var allTrue = true
            for row in 0..<3 {
                if board[row][col] == false {
                    allTrue = false
                    break
                }
            }
            if allTrue { lines += 1 }
        }

        var diagonalAllTrue = true
        for index in 0..<3 {
            if board[index][index] == false {
                diagonalAllTrue = false
                break
            }
        }
        if diagonalAllTrue { lines += 1 }

        diagonalAllTrue = true
        for index in 0..<3 {
            if board[index][2 - index] == false {
                diagonalAllTrue = false
                break
            }
        }
        if diagonalAllTrue { lines += 1 }

        return lines
    }

    func buildBingoBoard(from assignments: [DailyTaskAssignment]) -> [[Bool]] {
        var board = Array(repeating: Array(repeating: false, count: 3), count: 3)
        let count = min(assignments.count, 9)

        for index in 0..<count {
            let row = index / 3
            let col = index % 3
            board[row][col] = assignments[index].isCompleted
        }

        return board
    }

    func refreshBingoStatus(
        dailyAssignments: [DailyTaskAssignment],
        actionMessage: String? = nil
    ) {
        let board = buildBingoBoard(from: dailyAssignments)
        let win = checkBingoWin(board: board)
        let newLineCount = countBingoLines(board: board)
        let gainedLines = max(newLineCount - self.bingoLineCount, 0)
        let gapToBingo = missingCellsToFirstBingo(board: board)
        self.hasBingoLine = win
        self.bingoLineCount = newLineCount

        if gainedLines > 0 {
            if newLineCount >= 6 {
                bingoFeedbackText = rotatingMessage(from: [
                    "🌈 You're unstoppable! \(newLineCount) lines completed!",
                    "🚀 On fire! You've already secured \(newLineCount) lines!",
                ])
            } else if newLineCount >= 3 {
                bingoFeedbackText = rotatingMessage(from: [
                    "🎉 Nice! You made \(newLineCount) lines!",
                    "🥳 Line-upgraded! \(newLineCount) lines completed.",
                ])
            } else {
                bingoFeedbackText = rotatingMessage(from: [
                    "🏆 Awesome! \(newLineCount) line completed!",
                    "✅ Great work! \(newLineCount) line made.",
                ])
            }
        } else if let actionMessage {
            bingoFeedbackText = actionMessage
        } else if dailyAssignments.isEmpty {
            bingoFeedbackText = rotatingMessage(from: [
                "✨ Ready to take on today's challenge?",
                "🚀 A new day starts with the first tile!",
                "🌱 Just getting started? Pick the easiest task first.",
                "🧩 Add tasks from the task list to start your day.",
            ])
        } else if win {
            bingoFeedbackText = rotatingMessage(from: [
                "🌈 You're on a roll! \(newLineCount) lines completed!",
                "🎯 Great form. Keep pushing for more lines!",
            ])
        } else if gapToBingo <= 1 {
            bingoFeedbackText = rotatingMessage(from: [
                "⚡ Keep the rhythm! 1 more task to complete a line!",
                "🔥 Push one more task to trigger Bingo!",
            ])
        } else if gapToBingo == 2 {
            bingoFeedbackText = rotatingMessage(from: [
                "🌟 Your first Bingo is getting close, 2 tasks to go!",
                "🚀 Great momentum! Finish 2 more tasks for a possible line!",
            ])
        } else {
            bingoFeedbackText = rotatingMessage(from: [
                "💡 Every completed task gets you closer to the next line.",
                "📈 Steady rhythm. Keep lighting up today's plan.",
            ])
        }

        if gainedLines > 0 {
            triggerBingoCelebration()
        } else if win == false {
            showBingoPopup = false
        }
    }

    func completionActionMessage(completedCount: Int, gapToBingo: Int) -> String {
        if gapToBingo <= 1 {
            return rotatingMessage(from: [
                "⚡ Keep the rhythm! 1 more task to complete a line!",
                "🔥 Keep it up! Just 1 more task for a Bingo!",
            ])
        }
        if gapToBingo == 2 {
            return rotatingMessage(from: [
                "🌟 Your first Bingo is close, just 2 tasks away!",
                "🚀 Great pace! Push 2 more tasks to make a line.",
            ])
        }
        return rotatingMessage(from: [
            "💪 \(completedCount) tasks completed. Keep going!",
            "👏 Progress +1 today. Stay consistent!",
        ])
    }

    func missingCellsToFirstBingo(board: [[Bool]]) -> Int {
        guard board.count == 3, board.allSatisfy({ $0.count == 3 }) else { return 3 }
        var maxFilled = 0

        for row in 0..<3 {
            var filled = 0
            for col in 0..<3 where board[row][col] { filled += 1 }
            maxFilled = max(maxFilled, filled)
        }
        for col in 0..<3 {
            var filled = 0
            for row in 0..<3 where board[row][col] { filled += 1 }
            maxFilled = max(maxFilled, filled)
        }

        var diagonal = 0
        for index in 0..<3 where board[index][index] { diagonal += 1 }
        maxFilled = max(maxFilled, diagonal)

        diagonal = 0
        for index in 0..<3 where board[index][2 - index] { diagonal += 1 }
        maxFilled = max(maxFilled, diagonal)

        return max(3 - maxFilled, 0)
    }

    func addCompletionRecord(
        task: StudyTask,
        minutes: Int,
        on targetDate: Date,
        existingRecords: [DailyCompletionRecord]
    ) {
        let completedAt = completionTimestamp(for: targetDate)
        let dayKey = targetDate.dateKey

        if let existing = existingRecords.first(where: { $0.task?.id == task.id && $0.dayKey == dayKey }) {
            existing.completedMinutes = minutes
            existing.completedAt = completedAt
        } else {
            modelContext.insert(
                DailyCompletionRecord(
                    task: task,
                    completedMinutes: minutes,
                    completedAt: completedAt,
                    dayKey: dayKey
                )
            )
        }
        saveContext()
    }

    func removeCompletionRecord(
        task: StudyTask,
        on targetDate: Date,
        existingRecords: [DailyCompletionRecord]
    ) {
        let dayKey = targetDate.dateKey
        for record in existingRecords where record.task?.id == task.id && record.dayKey == dayKey {
            modelContext.delete(record)
        }
        saveContext()
    }

    private func rotatingMessage(from options: [String]) -> String {
        guard options.isEmpty == false else { return "✨ Ready to take on today's challenge?" }
        let index = feedbackTick % options.count
        feedbackTick += 1
        return options[index]
    }

    private func completionTimestamp(for targetDate: Date) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let second = calendar.component(.second, from: now)
        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: second,
            of: targetDate
        ) ?? targetDate
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed saving SwiftData context: \(error)")
        }
    }

    private func triggerBingoCelebration() {
        confettiBurstID += 1
        showBingoPopup = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.showBingoPopup = false
        }
    }
}

extension Date {
    private static let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()

    var dateKey: String {
        Self.dateKeyFormatter.string(from: self)
    }

    static func fromDateKey(_ dayKey: String) -> Date? {
        dateKeyFormatter.date(from: dayKey)
    }
}
