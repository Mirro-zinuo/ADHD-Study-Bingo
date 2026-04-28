import SwiftUI
import SwiftData

struct HomePageView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Query private var dailyCompletionRecords: [DailyCompletionRecord]
    @Query private var tasks: [StudyTask]
    let dailyAssignments: [DailyTaskAssignment]

    private static let chineseDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter
    }()

    private var isViewingToday: Bool {
        Calendar.current.isDate(appModel.selectedDate, inSameDayAs: Date())
    }

    var body: some View {
        @Bindable var appModel = appModel

        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("ADHD Study Bingo")
                        .font(.system(size: 40, weight: .bold, design: .rounded))

                    Text("Turn your tasks into a game")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 14) {
                        Button {
                            appModel.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: appModel.selectedDate) ?? appModel.selectedDate
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                        }
                        .buttonStyle(.bordered)

                        VStack(spacing: 2) {
                            Text(Self.chineseDateFormatter.string(from: appModel.selectedDate))
                                .font(.headline)
                            if isViewingToday == false {
                                Button("Back to Today") {
                                    appModel.selectedDate = Calendar.current.startOfDay(for: Date())
                                }
                                .font(.caption)
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        Button {
                            appModel.selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: appModel.selectedDate) ?? appModel.selectedDate
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.headline)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    bingoSection

                    Text("Designed for focus & relaxation")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.gray.opacity(0.55))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 10)
                }
                .padding(20)
            }
            .background(
                LinearGradient(
                    colors: [Color.white, Color.gray.opacity(0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )

            BingoCelebrationOverlay(
                showPopup: $appModel.showBingoPopup,
                confettiBurstID: appModel.confettiBurstID,
                lineCount: appModel.bingoLineCount
            )
            .opacity(appModel.showBingoPopup ? 1 : 0)
            .allowsHitTesting(appModel.showBingoPopup)
        }
    }

    private var bingoSection: some View {
        let board = appModel.buildBingoBoard(from: dailyAssignments)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(appModel.bingoFeedbackText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.92))
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .center)

            VStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(0..<3, id: \.self) { col in
                            let index = row * 3 + col
                            let assignment = assignmentAt(index)

                            Button {
                                toggleBingoTask(at: index)
                            } label: {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(tileColor(for: assignment))
                                    .frame(width: 106, height: 92)
                                    .overlay {
                                        VStack(spacing: 6) {
                                            Text(tileTitle(for: assignment))
                                                .font(.caption.weight(.semibold))
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                                .foregroundStyle(assignment?.isCompleted == true ? .white : .primary)

                                            if let assignment {
                                                Text("\(assignment.plannedMinutes) min")
                                                    .font(.caption2)
                                                    .foregroundStyle(assignment.isCompleted ? .white.opacity(0.9) : .secondary)
                                            }
                                        }
                                        .padding(6)
                                    }
                            }
                            .buttonStyle(.plain)
                            .disabled(assignment == nil)
                        }
                    }
                }
            }

            if appModel.hasBingoLine {
                Text("Bingo! You completed \(appModel.bingoLineCount) \(appModel.bingoLineCount == 1 ? "line" : "lines").")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            }

            Text("Scheduled \(dailyAssignments.count)/9 tasks for this day")
                .font(.caption)
                .foregroundStyle(.secondary)

            if appModel.checkBingoWin(board: board) == false && dailyAssignments.isEmpty {
                Text("Add tasks for this day from the task list first.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func assignmentAt(_ index: Int) -> DailyTaskAssignment? {
        guard index < dailyAssignments.count else { return nil }
        return dailyAssignments[index]
    }

    private func tileTitle(for assignment: DailyTaskAssignment?) -> String {
        guard let assignment,
              let title = assignment.task?.title else {
            return "Empty"
        }
        return title
    }

    private func tileColor(for assignment: DailyTaskAssignment?) -> Color {
        guard let assignment else { return Color.gray.opacity(0.15) }
        return assignment.isCompleted ? Color.green : Color.white.opacity(0.95)
    }

    private func toggleBingoTask(at index: Int) {
        guard index < dailyAssignments.count else { return }

        let assignment = dailyAssignments[index]
        guard let linkedTask = assignment.task else { return }
        let nowCompleting = (assignment.isCompleted == false)
        let delta = assignment.isCompleted ? -assignment.plannedMinutes : assignment.plannedMinutes
        let taskName = linkedTask.title

        assignment.isCompleted.toggle()
        let newCompleted = linkedTask.completedMinutes + delta
        linkedTask.completedMinutes = min(max(newCompleted, 0), linkedTask.totalMinutes)
        _ = appModel.recalculatePlan(tasks: tasks, todayActualMinutes: 0, focusedTaskID: nil)
        try? modelContext.save()

        let currentBoard = appModel.buildBingoBoard(from: dailyAssignments)
        let completedCount = dailyAssignments.filter(\.isCompleted).count
        let gapToBingo = appModel.missingCellsToFirstBingo(board: currentBoard)
        let actionMessage = assignment.isCompleted
            ? "↩️ Unmarked \(taskName) as completed"
            : appModel.completionActionMessage(completedCount: completedCount, gapToBingo: gapToBingo)

        if nowCompleting {
            appModel.addCompletionRecord(
                task: linkedTask,
                minutes: assignment.plannedMinutes,
                on: appModel.selectedDate,
                existingRecords: dailyCompletionRecords
            )
        } else {
            appModel.removeCompletionRecord(
                task: linkedTask,
                on: appModel.selectedDate,
                existingRecords: dailyCompletionRecords
            )
        }

        appModel.refreshBingoStatus(dailyAssignments: dailyAssignments, actionMessage: actionMessage,canBingo: true)
    }
}
