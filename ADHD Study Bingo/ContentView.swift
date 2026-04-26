import SwiftUI

struct StudyTask: Identifiable {
    let id: UUID
    var title: String
    var totalMinutes: Int
    var completedMinutes: Int
    var daysLeft: Int
    var deadlineDate: Date
    var initialDays: Int
    var dailyTargetMinutes: Double

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

        let calculatedDays = calculateDaysLeft(from: today, to: deadlineDate)
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
}

struct DailyTaskAssignment: Identifiable {
    let id: UUID
    var taskID: UUID
    var plannedMinutes: Int
    var isCompleted: Bool

    init(taskID: UUID, plannedMinutes: Int, isCompleted: Bool = false) {
        self.id = UUID()
        self.taskID = taskID
        self.plannedMinutes = plannedMinutes
        self.isCompleted = isCompleted
    }
}

struct DailyCompletionRecord: Identifiable {
    var taskID: UUID
    var taskTitle: String
    var completedMinutes: Int
    var completedAt: Date

    var id: UUID { taskID }
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
    var updated = tasks

    for index in updated.indices {
        updated[index].daysLeft = calculateDaysLeft(from: currentDate, to: updated[index].deadlineDate)
    }

    if let focusedTaskID,
       let index = updated.firstIndex(where: { $0.id == focusedTaskID }) {
        let safeMinutes = max(todayActualMinutes, 0)
        updated[index].completedMinutes = min(
            updated[index].completedMinutes + safeMinutes,
            updated[index].totalMinutes
        )
    }

    for index in updated.indices {
        let remaining = max(updated[index].totalMinutes - updated[index].completedMinutes, 0)
        if remaining == 0 {
            updated[index].dailyTargetMinutes = 0
        } else {
            updated[index].dailyTargetMinutes = Double(remaining) / Double(max(updated[index].daysLeft, 1))
        }
    }

    return updated
}

func urgencyScore(for task: StudyTask) -> Double {
    let remainingRatio = Double(task.remainingMinutes) / Double(max(task.totalMinutes, 1))
    return task.dailyTargetMinutes * (1 + remainingRatio)
}

func sortByUrgency(_ tasks: [StudyTask]) -> [StudyTask] {
    tasks.sorted { urgencyScore(for: $0) > urgencyScore(for: $1) }
}

enum UrgencyLevel {
    case green
    case orange
    case red

    var color: Color {
        switch self {
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        }
    }
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

struct TaskBarsView: View {
    let task: StudyTask

    private func redToGreenColor(progress: Double) -> Color {
        let clamped = min(max(progress, 0), 1)
        // hue: 0 (red) -> 0.33 (green)
        return Color(hue: 0.33 * clamped, saturation: 0.78, brightness: 0.90)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: task.remainingProgress)
                .tint(redToGreenColor(progress: task.remainingProgress))
            Text("Remaining Time Progress")
                .font(.caption2)
                .foregroundStyle(.secondary)

            ProgressView(value: task.completedProgress)
                .tint(redToGreenColor(progress: task.completedProgress))
            Text("Completion Progress")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct BingoCelebrationOverlay: View {
    @Binding var showPopup: Bool
    @Binding var confettiDrop: Bool
    let lineCount: Int

    private let confettiColors: [Color] = [
        Color.green.opacity(0.70),
        Color.yellow.opacity(0.85),
        Color.gray.opacity(0.60)
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.12)
                .ignoresSafeArea()

            ForEach(0..<24, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(confettiColors[index % confettiColors.count])
                    .frame(width: 8, height: 14)
                    .rotationEffect(.degrees(Double((index * 23) % 70)))
                    .offset(
                        x: CGFloat((index % 8) - 4) * 48 + CGFloat((index % 3) * 6),
                        y: confettiDrop ? CGFloat(80 + (index / 8) * 140) : -220
                    )
                    .animation(
                        .easeOut(duration: 0.85).delay(Double(index) * 0.02),
                        value: confettiDrop
                    )
            }

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.green.opacity(0.65), lineWidth: 2)
                )
                .frame(width: 300, height: 120)
                .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 7)
                .overlay {
                    VStack(spacing: 6) {
                        Text("🎉 BINGO!")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.green.opacity(0.72))
                        Text("Awesome! \(lineCount) lines completed")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .scaleEffect(showPopup ? 1 : 0.82)
                .opacity(showPopup ? 1 : 0)
                .animation(.spring(response: 0.32, dampingFraction: 0.72), value: showPopup)
        }
        .transition(.opacity)
    }
}

struct ContentView: View {
    @State private var tasks: [StudyTask] = [
        StudyTask(title: "CS Project", totalMinutes: 300, completedMinutes: 60, deadlineDate: Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()),
        StudyTask(title: "History Essay", totalMinutes: 180, completedMinutes: 30, deadlineDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()),
        StudyTask(title: "Math Review", totalMinutes: 240, completedMinutes: 80, deadlineDate: Calendar.current.date(byAdding: .day, value: 6, to: Date()) ?? Date())
    ]

    @State private var dailyAssignmentsByDate: [String: [DailyTaskAssignment]] = [:]
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var hasBingoLine: Bool = false
    @State private var bingoLineCount: Int = 0
    @State private var showBingoPopup: Bool = false
    @State private var confettiDrop: Bool = false
    @State private var bingoFeedbackText: String = "⚡ Keep the rhythm! Tap a tile to check in."
    @State private var feedbackTick: Int = 0
    @State private var completionHistory: [String: [DailyCompletionRecord]] = [:]

    @State private var showAddTaskSheet: Bool = false
    @State private var newTitle: String = ""
    @State private var newHours: Int = 1
    @State private var newMinutes: Int = 0
    @State private var newDeadline: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @State private var showEditTaskSheet: Bool = false
    @State private var editingTaskID: UUID?
    @State private var editTitle: String = ""
    @State private var editHours: Int = 1
    @State private var editMinutes: Int = 0
    @State private var editDeadline: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @State private var showDeleteTaskAlert: Bool = false
    @State private var pendingDeleteTaskID: UUID?
    @State private var showTaskActionMenu: Bool = false
    @State private var taskActionMenuTaskID: UUID?

    @State private var showDailyPlanSheet: Bool = false
    @State private var pendingTaskID: UUID?
    @State private var pendingDailyMinutesInput: String = ""
    @State private var showBoardFullAlert: Bool = false
    @State private var showPlanLimitAlert: Bool = false
    @State private var planLimitAlertMessage: String = ""

    private var pendingTasks: [StudyTask] {
        sortByUrgency(tasks.filter { $0.remainingMinutes > 0 })
    }

    private var completedTasks: [StudyTask] {
        tasks.filter { $0.remainingMinutes == 0 }
            .sorted { $0.title < $1.title }
    }

    private var sortedHistoryDayKeys: [String] {
        completionHistory.keys.sorted { lhs, rhs in
            guard let leftDate = historyDayFormatter.date(from: lhs),
                  let rightDate = historyDayFormatter.date(from: rhs) else {
                return lhs > rhs
            }
            return leftDate > rightDate
        }
    }

    private var pendingDeleteTaskName: String {
        guard let pendingDeleteTaskID,
              let task = tasks.first(where: { $0.id == pendingDeleteTaskID }) else {
            return "this task"
        }
        return task.title
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }

    private var chineseDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter
    }

    private var historyDayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }

    private var historyTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }

    private var selectedDayKey: String {
        historyDayKey(for: selectedDate)
    }

    private var currentDailyAssignments: [DailyTaskAssignment] {
        dailyAssignmentsByDate[selectedDayKey] ?? []
    }

    private var isViewingToday: Bool {
        Calendar.current.isDate(selectedDate, inSameDayAs: Date())
    }

    var body: some View {
        TabView {
            homePage
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            taskListPage
                .tabItem {
                    Label("Tasks", systemImage: "list.bullet.rectangle")
                }

            historyPage
                .tabItem {
                    Label("History", systemImage: "clock")
                }
        }
        .onAppear {
            tasks = sortByUrgency(recalculatePlan(tasks: tasks, todayActualMinutes: 0, focusedTaskID: nil))
            refreshBingoStatus()
        }
        .onChange(of: selectedDate) { _, _ in
            refreshBingoStatus()
        }
        .sheet(isPresented: $showAddTaskSheet) {
            addTaskSheet
        }
        .sheet(isPresented: $showEditTaskSheet) {
            editTaskSheet
        }
        .sheet(isPresented: $showDailyPlanSheet) {
            addDailyPlanSheet
        }
        .alert("Up to 9 Tasks Per Day", isPresented: $showBoardFullAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert("Daily Plan Exceeds Remaining Time", isPresented: $showPlanLimitAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(planLimitAlertMessage)
        }
        .alert("Delete Task?", isPresented: $showDeleteTaskAlert) {
            Button("Delete", role: .destructive) {
                deleteTask()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove \"\(pendingDeleteTaskName)\" and its daily assignments.")
        }
        .confirmationDialog("Task Actions", isPresented: $showTaskActionMenu, titleVisibility: .visible) {
            Button("Edit Task") {
                if let taskActionMenuTaskID,
                   let task = tasks.first(where: { $0.id == taskActionMenuTaskID }) {
                    openEditTaskSheet(for: task)
                }
                taskActionMenuTaskID = nil
            }
            Button("Delete Task", role: .destructive) {
                if let taskActionMenuTaskID {
                    prepareDeleteTask(taskID: taskActionMenuTaskID)
                }
                taskActionMenuTaskID = nil
            }
            Button("Cancel", role: .cancel) {
                taskActionMenuTaskID = nil
            }
        }
    }

    private var homePage: some View {
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
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                        }
                        .buttonStyle(.bordered)

                        VStack(spacing: 2) {
                            Text(chineseDateFormatter.string(from: selectedDate))
                                .font(.headline)
                            if isViewingToday == false {
                                Button("Back to Today") {
                                    selectedDate = Calendar.current.startOfDay(for: Date())
                                }
                                .font(.caption)
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        Button {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
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

            if showBingoPopup {
                BingoCelebrationOverlay(
                    showPopup: $showBingoPopup,
                    confettiDrop: $confettiDrop,
                    lineCount: bingoLineCount
                )
            }
        }
    }

    private var taskListPage: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Task List")
                        .font(.system(size: 30, weight: .bold, design: .rounded))

                    Text("Active Tasks")
                        .font(.headline)

                    ForEach(pendingTasks) { task in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(task.title)
                                    .font(.headline)
                                Spacer()
                                Text("Deadline \(dateFormatter.string(from: task.deadlineDate))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Text("Remaining \(task.remainingMinutes) min | Completed \(task.completedMinutes) min | Days Left \(task.daysLeft)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("Recommended Today: \(max(Int(ceil(task.dailyTargetMinutes)), 1)) min")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            TaskBarsView(task: task)

                            HStack(spacing: 10) {
                                if dailyAssignmentIndex(for: task.id) == nil {
                                    Button {
                                        openDailyPlanSheet(for: task)
                                    } label: {
                                        Image(systemName: "plus")
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .accessibilityLabel("Add to Daily Tasks")
                                } else {
                                    Button {
                                        openDailyPlanSheet(for: task)
                                    } label: {
                                        Image(systemName: "pencil")
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .accessibilityLabel("Edit Daily Plan")

                                    Button {
                                        removeDailyTask(taskID: task.id)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.red)
                                    .accessibilityLabel("Remove from Daily Tasks")
                                }

                                Spacer(minLength: 0)

                                Button {
                                    openTaskActionMenu(for: task.id)
                                } label: {
                                    Image(systemName: "ellipsis")
                                }
                                .buttonStyle(.bordered)
                                .accessibilityLabel("More Task Actions")
                            }
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }

                    if completedTasks.isEmpty == false {
                        Text("Completed Tasks")
                            .font(.headline)
                            .padding(.top, 6)

                        ForEach(completedTasks) { task in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(task.title)
                                        .font(.headline)
                                    Spacer()
                                    Text("Completed")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.green)
                                }

                                Text("Total \(task.totalMinutes) min | Completed \(task.completedMinutes) min")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                TaskBarsView(task: task)

                                HStack {
                                    Spacer(minLength: 0)
                                    Button {
                                        openTaskActionMenu(for: task.id)
                                    } label: {
                                        Image(systemName: "ellipsis")
                                    }
                                    .buttonStyle(.bordered)
                                    .accessibilityLabel("More Task Actions")
                                }
                            }
                            .padding(14)
                            .background(Color.green.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.gray.opacity(0.08))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Task") {
                        showAddTaskSheet = true
                    }
                }
            }
        }
    }

    private var historyPage: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Daily Completion History")
                        .font(.system(size: 30, weight: .bold, design: .rounded))

                    if sortedHistoryDayKeys.isEmpty {
                        Text("No history yet. Completed daily tasks will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sortedHistoryDayKeys, id: \.self) { dayKey in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(dayKey)
                                    .font(.headline)

                                if let records = completionHistory[dayKey] {
                                    ForEach(records.sorted(by: { $0.completedAt > $1.completedAt })) { record in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(record.taskTitle)
                                                    .font(.subheadline.weight(.semibold))
                                                Text("Completed \(record.completedMinutes) min")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Text(historyTimeFormatter.string(from: record.completedAt))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(10)
                                        .background(Color.white.opacity(0.9))
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                }
                            }
                            .padding(14)
                            .background(Color.green.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.gray.opacity(0.08))
        }
    }

    private var bingoSection: some View {
        let board = buildBingoBoard(from: currentDailyAssignments)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(bingoFeedbackText)
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

            if hasBingoLine {
                Text("Bingo! You completed a line.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            }

            Text("Scheduled \(currentDailyAssignments.count)/9 tasks for this day")
                .font(.caption)
                .foregroundStyle(.secondary)

            if checkBingoWin(board: board) == false && currentDailyAssignments.isEmpty {
                Text("Add tasks for this day from the task list first.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var addTaskSheet: some View {
        NavigationStack {
            Form {
                Section("Task Info") {
                    TextField("Task Name", text: $newTitle)
                    HStack(spacing: 12) {
                        Picker("Hours", selection: $newHours) {
                            ForEach(0..<24, id: \.self) { value in
                                Text("\(value) h").tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity, maxHeight: 110)

                        Picker("Minutes", selection: $newMinutes) {
                            ForEach(0..<60, id: \.self) { value in
                                Text("\(value) min").tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity, maxHeight: 110)
                    }
                    DatePicker("Deadline", selection: $newDeadline, displayedComponents: .date)
                }
            }
            .navigationTitle("Add Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddTaskSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addTask()
                    }
                    .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var addDailyPlanSheet: some View {
        NavigationStack {
            Form {
                Section("Daily Planned Time") {
                    TextField("Minutes", text: $pendingDailyMinutesInput)
                }
            }
            .navigationTitle("Add to Daily Tasks")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showDailyPlanSheet = false
                        pendingTaskID = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDailyPlan()
                    }
                }
            }
        }
    }

    private var editTaskSheet: some View {
        NavigationStack {
            Form {
                Section("Edit Task Info") {
                    TextField("Task Name", text: $editTitle)
                    HStack(spacing: 12) {
                        Picker("Hours", selection: $editHours) {
                            ForEach(0..<24, id: \.self) { value in
                                Text("\(value) h").tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity, maxHeight: 110)

                        Picker("Minutes", selection: $editMinutes) {
                            ForEach(0..<60, id: \.self) { value in
                                Text("\(value) min").tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity, maxHeight: 110)
                    }
                    DatePicker("Deadline", selection: $editDeadline, displayedComponents: .date)
                }
            }
            .navigationTitle("Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showEditTaskSheet = false
                        editingTaskID = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEditedTask()
                    }
                    .disabled(editTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func assignmentAt(_ index: Int) -> DailyTaskAssignment? {
        let assignments = currentDailyAssignments
        guard index < assignments.count else { return nil }
        return assignments[index]
    }

    private func tileTitle(for assignment: DailyTaskAssignment?) -> String {
        guard let assignment,
              let task = tasks.first(where: { $0.id == assignment.taskID }) else {
            return "Empty"
        }
        return task.title
    }

    private func tileColor(for assignment: DailyTaskAssignment?) -> Color {
        guard let assignment else { return Color.gray.opacity(0.15) }
        return assignment.isCompleted ? Color.green : Color.white.opacity(0.95)
    }

    private func openDailyPlanSheet(for task: StudyTask) {
        if currentDailyAssignments.count >= 9 && dailyAssignmentIndex(for: task.id) == nil {
            showBoardFullAlert = true
            return
        }
        if task.remainingMinutes == 0 {
            planLimitAlertMessage = "This task has 0 remaining time. Completed tasks cannot be added again."
            showPlanLimitAlert = true
            return
        }

        pendingTaskID = task.id

        let assignments = currentDailyAssignments
        if let index = dailyAssignmentIndex(for: task.id) {
            pendingDailyMinutesInput = String(assignments[index].plannedMinutes)
        } else {
            pendingDailyMinutesInput = String(max(Int(ceil(task.dailyTargetMinutes)), 1))
        }

        showDailyPlanSheet = true
    }

    private func openEditTaskSheet(for task: StudyTask) {
        editingTaskID = task.id
        editTitle = task.title
        editHours = task.totalMinutes / 60
        editMinutes = task.totalMinutes % 60
        editDeadline = task.deadlineDate
        showEditTaskSheet = true
    }

    private func openTaskActionMenu(for taskID: UUID) {
        taskActionMenuTaskID = taskID
        showTaskActionMenu = true
    }

    private func saveEditedTask() {
        guard let editingTaskID,
              let index = tasks.firstIndex(where: { $0.id == editingTaskID }) else { return }

        let total = max(editHours * 60 + editMinutes, 1)
        let trimmedTitle = editTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        tasks[index].title = trimmedTitle
        tasks[index].totalMinutes = total
        tasks[index].deadlineDate = editDeadline
        tasks[index].completedMinutes = min(tasks[index].completedMinutes, total)
        tasks[index].initialDays = calculateDaysLeft(from: Date(), to: editDeadline)

        tasks = sortByUrgency(recalculatePlan(tasks: tasks, todayActualMinutes: 0, focusedTaskID: nil))

        if let assignmentIndex = dailyAssignmentIndex(for: editingTaskID) {
            let maxPlan = max(tasks.first(where: { $0.id == editingTaskID })?.remainingMinutes ?? 1, 1)
            var assignments = currentDailyAssignments
            assignments[assignmentIndex].plannedMinutes = min(assignments[assignmentIndex].plannedMinutes, maxPlan)
            setCurrentDailyAssignments(assignments)
        }
        updateTaskTitleInHistory(taskID: editingTaskID, newTitle: trimmedTitle)

        showEditTaskSheet = false
        self.editingTaskID = nil
        refreshBingoStatus(actionMessage: "✏️ Task updated.")
    }

    private func prepareDeleteTask(taskID: UUID) {
        pendingDeleteTaskID = taskID
        showDeleteTaskAlert = true
    }

    private func deleteTask() {
        guard let pendingDeleteTaskID else { return }

        tasks.removeAll(where: { $0.id == pendingDeleteTaskID })
        removeTaskFromAllAssignments(taskID: pendingDeleteTaskID)
        removeTaskFromAllHistory(taskID: pendingDeleteTaskID)

        if pendingTaskID == pendingDeleteTaskID {
            pendingTaskID = nil
            showDailyPlanSheet = false
        }

        if editingTaskID == pendingDeleteTaskID {
            editingTaskID = nil
            showEditTaskSheet = false
        }

        tasks = sortByUrgency(recalculatePlan(tasks: tasks, todayActualMinutes: 0, focusedTaskID: nil))
        showDeleteTaskAlert = false
        self.pendingDeleteTaskID = nil
        refreshBingoStatus(actionMessage: "🗑️ Task deleted.")
    }

    private func saveDailyPlan() {
        guard let pendingTaskID else { return }

        let planned = max(Int(pendingDailyMinutesInput) ?? 0, 1)
        guard let task = tasks.first(where: { $0.id == pendingTaskID }) else { return }
        let assignments = currentDailyAssignments
        let existingAssignment = dailyAssignmentIndex(for: pendingTaskID).flatMap { assignments[$0] }
        let extraIfCompleted = (existingAssignment?.isCompleted == true) ? (existingAssignment?.plannedMinutes ?? 0) : 0
        let maxAllowed = max(task.remainingMinutes + extraIfCompleted, 0)

        if planned > maxAllowed {
            planLimitAlertMessage = "Planned \(planned) min exceeds remaining \(maxAllowed) min."
            showPlanLimitAlert = true
            return
        }

        if let index = dailyAssignmentIndex(for: pendingTaskID) {
            var updatedAssignments = currentDailyAssignments
            if updatedAssignments[index].isCompleted {
                tasks = applyCompletionDelta(taskID: pendingTaskID, deltaMinutes: -updatedAssignments[index].plannedMinutes)
                updatedAssignments[index].isCompleted = false
                removeCompletionRecord(taskID: pendingTaskID, on: selectedDate)
            }
            updatedAssignments[index].plannedMinutes = planned
            setCurrentDailyAssignments(updatedAssignments)
        } else {
            var updatedAssignments = currentDailyAssignments
            updatedAssignments.append(DailyTaskAssignment(taskID: pendingTaskID, plannedMinutes: planned))
            setCurrentDailyAssignments(updatedAssignments)
        }

        showDailyPlanSheet = false
        self.pendingTaskID = nil
        pendingDailyMinutesInput = ""
        refreshBingoStatus(actionMessage: "🧩 Daily plan updated.")
    }

    private func toggleBingoTask(at index: Int) {
        var updatedAssignments = currentDailyAssignments
        guard index < updatedAssignments.count else { return }

        let assignment = updatedAssignments[index]
        let nowCompleting = (assignment.isCompleted == false)
        let delta = assignment.isCompleted ? -assignment.plannedMinutes : assignment.plannedMinutes
        let taskName = tasks.first(where: { $0.id == assignment.taskID })?.title ?? "Task"

        updatedAssignments[index].isCompleted.toggle()
        setCurrentDailyAssignments(updatedAssignments)
        tasks = applyCompletionDelta(taskID: assignment.taskID, deltaMinutes: delta)

        let currentBoard = buildBingoBoard(from: updatedAssignments)
        let completedCount = updatedAssignments.filter(\.isCompleted).count
        let gapToBingo = missingCellsToFirstBingo(board: currentBoard)
        let actionMessage = assignment.isCompleted
            ? "↩️ Unmarked \(taskName) as completed"
            : completionActionMessage(completedCount: completedCount, gapToBingo: gapToBingo)

        if nowCompleting {
            addCompletionRecord(
                taskID: assignment.taskID,
                taskTitle: taskName,
                minutes: assignment.plannedMinutes,
                on: selectedDate
            )
        } else {
            removeCompletionRecord(taskID: assignment.taskID, on: selectedDate)
        }

        refreshBingoStatus(animated: true, actionMessage: actionMessage)
    }

    private func applyCompletionDelta(taskID: UUID, deltaMinutes: Int) -> [StudyTask] {
        var updated = tasks

        if let taskIndex = updated.firstIndex(where: { $0.id == taskID }) {
            let newValue = updated[taskIndex].completedMinutes + deltaMinutes
            updated[taskIndex].completedMinutes = min(max(newValue, 0), updated[taskIndex].totalMinutes)
        }

        let recalculated = recalculatePlan(tasks: updated, todayActualMinutes: 0, focusedTaskID: nil)
        return sortByUrgency(recalculated)
    }

    private func removeDailyTask(taskID: UUID) {
        guard let index = dailyAssignmentIndex(for: taskID) else { return }
        var assignments = currentDailyAssignments
        let taskName = tasks.first(where: { $0.id == taskID })?.title ?? "Task"

        if assignments[index].isCompleted {
            tasks = applyCompletionDelta(taskID: taskID, deltaMinutes: -assignments[index].plannedMinutes)
            removeCompletionRecord(taskID: taskID, on: selectedDate)
        }

        assignments.remove(at: index)
        setCurrentDailyAssignments(assignments)
        refreshBingoStatus(actionMessage: "🗂️ Removed \(taskName) from daily tasks.")
    }

    private func dailyAssignmentIndex(for taskID: UUID) -> Int? {
        currentDailyAssignments.firstIndex(where: { $0.taskID == taskID })
    }

    private func setCurrentDailyAssignments(_ assignments: [DailyTaskAssignment]) {
        if assignments.isEmpty {
            dailyAssignmentsByDate.removeValue(forKey: selectedDayKey)
        } else {
            dailyAssignmentsByDate[selectedDayKey] = assignments
        }
    }

    private func removeTaskFromAllAssignments(taskID: UUID) {
        for key in dailyAssignmentsByDate.keys {
            guard var assignments = dailyAssignmentsByDate[key] else { continue }
            assignments.removeAll(where: { $0.taskID == taskID })
            if assignments.isEmpty {
                dailyAssignmentsByDate.removeValue(forKey: key)
            } else {
                dailyAssignmentsByDate[key] = assignments
            }
        }
    }

    private func rotatingMessage(from options: [String]) -> String {
        guard options.isEmpty == false else { return "✨ Ready to take on today's challenge?" }
        let index = feedbackTick % options.count
        feedbackTick += 1
        return options[index]
    }

    private func missingCellsToFirstBingo(board: [[Bool]]) -> Int {
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

    private func completionActionMessage(completedCount: Int, gapToBingo: Int) -> String {
        if gapToBingo <= 1 {
            return rotatingMessage(from: [
                "⚡ Keep the rhythm! 1 more task to complete a line!",
                "🔥 Keep it up! Just 1 more task for a Bingo!"
            ])
        }
        if gapToBingo == 2 {
            return rotatingMessage(from: [
                "🌟 Your first Bingo is close, just 2 tasks away!",
                "🚀 Great pace! Push 2 more tasks to make a line."
            ])
        }
        return rotatingMessage(from: [
            "💪 \(completedCount) tasks completed. Keep going!",
            "👏 Progress +1 today. Stay consistent!"
        ])
    }

    private func refreshBingoStatus(animated: Bool = false, actionMessage: String? = nil) {
        let board = buildBingoBoard(from: currentDailyAssignments)
        let win = checkBingoWin(board: board)
        let newLineCount = countBingoLines(board: board)
        let gainedLines = max(newLineCount - bingoLineCount, 0)
        let gapToBingo = missingCellsToFirstBingo(board: board)

        if animated {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                hasBingoLine = win
            }
        } else {
            hasBingoLine = win
        }

        bingoLineCount = newLineCount

        if gainedLines > 0 {
            if newLineCount >= 6 {
                bingoFeedbackText = rotatingMessage(from: [
                    "🌈 You're unstoppable! \(newLineCount) lines completed!",
                    "🚀 On fire! You've already secured \(newLineCount) lines!"
                ])
            } else if newLineCount >= 3 {
                bingoFeedbackText = rotatingMessage(from: [
                    "🎉 Nice! You made \(newLineCount) lines!",
                    "🥳 Line-upgraded! \(newLineCount) lines completed."
                ])
            } else {
                bingoFeedbackText = rotatingMessage(from: [
                    "🏆 Awesome! \(newLineCount) line completed!",
                    "✅ Great work! \(newLineCount) line made."
                ])
            }
            triggerBingoCelebration()
        } else if let actionMessage {
            bingoFeedbackText = actionMessage
        } else if currentDailyAssignments.isEmpty {
            bingoFeedbackText = rotatingMessage(from: [
                "✨ Ready to take on today's challenge?",
                "🚀 A new day starts with the first tile!",
                "🌱 Just getting started? Pick the easiest task first.",
                "🧩 Add tasks from the task list to start your day."
            ])
        } else if hasBingoLine {
            bingoFeedbackText = rotatingMessage(from: [
                "🌈 You're on a roll! \(newLineCount) lines completed!",
                "🎯 Great form. Keep pushing for more lines!"
            ])
        } else if gapToBingo <= 1 {
            bingoFeedbackText = rotatingMessage(from: [
                "⚡ Keep the rhythm! 1 more task to complete a line!",
                "🔥 Push one more task to trigger Bingo!"
            ])
        } else if gapToBingo == 2 {
            bingoFeedbackText = rotatingMessage(from: [
                "🌟 Your first Bingo is getting close, 2 tasks to go!",
                "🚀 Great momentum! Finish 2 more tasks for a possible line!"
            ])
        } else {
            bingoFeedbackText = rotatingMessage(from: [
                "💡 Every completed task gets you closer to the next line.",
                "📈 Steady rhythm. Keep lighting up today's plan."
            ])
        }

        if win == false {
            showBingoPopup = false
            confettiDrop = false
        }
    }

    private func triggerBingoCelebration() {
        confettiDrop = false
        withAnimation(.easeOut(duration: 0.18)) {
            showBingoPopup = true
        }
        withAnimation(.easeOut(duration: 0.95).delay(0.04)) {
            confettiDrop = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.65) {
            withAnimation(.easeIn(duration: 0.2)) {
                showBingoPopup = false
            }
            confettiDrop = false
        }
    }

    private func historyDayKey(for date: Date = Date()) -> String {
        historyDayFormatter.string(from: date)
    }

    private func addCompletionRecord(taskID: UUID, taskTitle: String, minutes: Int, on targetDate: Date) {
        let completedAt = completionTimestamp(for: targetDate)
        let dayKey = historyDayKey(for: targetDate)
        var records = completionHistory[dayKey] ?? []

        if let index = records.firstIndex(where: { $0.taskID == taskID }) {
            records[index].taskTitle = taskTitle
            records[index].completedMinutes = minutes
            records[index].completedAt = completedAt
        } else {
            records.append(
                DailyCompletionRecord(
                    taskID: taskID,
                    taskTitle: taskTitle,
                    completedMinutes: minutes,
                    completedAt: completedAt
                )
            )
        }

        completionHistory[dayKey] = records
    }

    private func removeCompletionRecord(taskID: UUID, on targetDate: Date) {
        let dayKey = historyDayKey(for: targetDate)
        guard var records = completionHistory[dayKey] else { return }

        records.removeAll(where: { $0.taskID == taskID })
        if records.isEmpty {
            completionHistory.removeValue(forKey: dayKey)
        } else {
            completionHistory[dayKey] = records
        }
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

    private func removeTaskFromAllHistory(taskID: UUID) {
        for key in completionHistory.keys {
            guard var records = completionHistory[key] else { continue }
            records.removeAll(where: { $0.taskID == taskID })
            if records.isEmpty {
                completionHistory.removeValue(forKey: key)
            } else {
                completionHistory[key] = records
            }
        }
    }

    private func updateTaskTitleInHistory(taskID: UUID, newTitle: String) {
        for key in completionHistory.keys {
            guard var records = completionHistory[key] else { continue }
            for index in records.indices where records[index].taskID == taskID {
                records[index].taskTitle = newTitle
            }
            completionHistory[key] = records
        }
    }

    private func addTask() {
        let total = max(newHours * 60 + newMinutes, 1)

        let newTask = StudyTask(
            title: newTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            totalMinutes: total,
            completedMinutes: 0,
            deadlineDate: newDeadline
        )

        tasks.append(newTask)
        tasks = recalculatePlan(tasks: tasks, todayActualMinutes: 0, focusedTaskID: nil)

        newTitle = ""
        newHours = 1
        newMinutes = 0
        newDeadline = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        showAddTaskSheet = false
    }
}

#Preview {
    ContentView()
}
