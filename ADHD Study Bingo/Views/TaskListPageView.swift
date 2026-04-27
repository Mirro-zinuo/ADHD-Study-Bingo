import SwiftData
import SwiftUI

struct TaskListPageView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Query private var dailyCompletionRecords: [DailyCompletionRecord]
    @Query private var tasks: [StudyTask]
    let dailyAssignments: [DailyTaskAssignment]
    @State private var dailyPlanDraft: DailyPlanDraft?
    @State private var showTaskActionMenu: Bool = false
    @State private var taskActionMenuTaskID: UUID?
    @State private var showDeleteTaskAlert: Bool = false
    @State private var pendingDeleteTaskID: UUID?
    @State private var showBoardFullAlert: Bool = false
    @State private var showPlanLimitAlert: Bool = false
    @State private var planLimitAlertMessage: String = ""
    @State private var showEditTaskSheet: Bool = false
    @State private var editingTaskID: UUID?
    @State private var showAddTaskSheet: Bool = false

    private var pendingTasks: [StudyTask] {
        appModel.sortByUrgency(tasks.filter { $0.remainingMinutes > 0 })
    }

    private var completedTasks: [StudyTask] {
        tasks.filter { $0.remainingMinutes == 0 }
            .sorted { $0.title < $1.title }
    }

    private var pendingDeleteTaskName: String {
        guard let pendingDeleteTaskID,
            let task = tasks.first(where: { $0.id == pendingDeleteTaskID })
        else {
            return "this task"
        }
        return task.title
    }

    private func assignmentIndex(for taskID: UUID) -> Int? {
        dailyAssignments.firstIndex(where: { $0.task?.id == taskID })
    }

    private func plannedMinutes(for taskID: UUID) -> Int? {
        guard let index = assignmentIndex(for: taskID) else { return nil }
        return dailyAssignments[index].plannedMinutes
    }

    private func latestDailyAssignments() -> [DailyTaskAssignment] {
        let dayKey = appModel.selectedDate.dateKey
        let descriptor = FetchDescriptor<DailyTaskAssignment>(
            predicate: #Predicate { $0.dayKey == dayKey },
            sortBy: [SortDescriptor(\.createdAt)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            assertionFailure("Failed fetching daily assignments: \(error)")
            return dailyAssignments
        }
    }

    var body: some View {
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
                                Text("Deadline \(task.deadlineDate.dateKey)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Text(
                                "Remaining \(task.remainingMinutes) min | Completed \(task.completedMinutes) min | Days Left \(task.daysLeft)"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            Text(
                                "Recommended Today: \(max(Int(ceil(task.dailyTargetMinutes)), 1)) min"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            TaskBarsView(task: task)

                            HStack(spacing: 10) {
                                if assignmentIndex(for: task.id) == nil {
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

                                Text(
                                    "Total \(task.totalMinutes) min | Completed \(task.completedMinutes) min"
                                )
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
        .sheet(item: $dailyPlanDraft) { draft in
            DailyPlanSheetView(
                initialMinutes: draft.minutesText,
                onAttemptSave: { text in
                    if let message = saveDailyPlan(taskID: draft.taskID, minutesInput: text) {
                        planLimitAlertMessage = message
                        showPlanLimitAlert = true
                        return false
                    }
                    dailyPlanDraft = nil
                    return true
                },
                onCancel: {
                    dailyPlanDraft = nil
                }
            )
        }
        .sheet(isPresented: $showEditTaskSheet) {
            Group {
                if let editingTaskID,
                    let task = tasks.first(where: { $0.id == editingTaskID })
                {
                    EditTaskSheetView(
                        initialTitle: task.title,
                        initialHours: task.totalMinutes / 60,
                        initialMinutes: task.totalMinutes % 60,
                        initialDeadline: task.deadlineDate,
                        onCommit: { title, hours, minutes, deadline in
                            saveEditedTask(
                                taskID: editingTaskID,
                                title: title,
                                hours: hours,
                                minutes: minutes,
                                deadline: deadline
                            )
                        },
                        onCancel: {
                            showEditTaskSheet = false
                            self.editingTaskID = nil
                        }
                    )
                }
            }
        }
        .alert("Delete Task?", isPresented: $showDeleteTaskAlert) {
            Button("Delete", role: .destructive) {
                confirmDeleteTask()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove \"\(pendingDeleteTaskName)\" and its daily assignments.")
        }
        .alert("Up to 9 Tasks Per Day", isPresented: $showBoardFullAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert("Daily Plan Exceeds Remaining Time", isPresented: $showPlanLimitAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(planLimitAlertMessage)
        }
        .confirmationDialog(
            "Task Actions", isPresented: $showTaskActionMenu, titleVisibility: .visible
        ) {
            Button("Edit Task") {
                if let taskActionMenuTaskID {
                    editingTaskID = taskActionMenuTaskID
                    showEditTaskSheet = true
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
        .sheet(isPresented: $showAddTaskSheet) {
            AddTaskSheetView()
        }
    }

    private func openDailyPlanSheet(for task: StudyTask) {
        if dailyAssignments.count >= 9 && assignmentIndex(for: task.id) == nil {
            showBoardFullAlert = true
            return
        }
        if task.remainingMinutes == 0 {
            planLimitAlertMessage =
                "This task has 0 remaining time. Completed tasks cannot be added again."
            showPlanLimitAlert = true
            return
        }

        let minutesText: String
        if let planned = plannedMinutes(for: task.id) {
            minutesText = String(planned)
        } else {
            minutesText = String(max(Int(ceil(task.dailyTargetMinutes)), 1))
        }
        dailyPlanDraft = DailyPlanDraft(taskID: task.id, minutesText: minutesText)
    }

    private func openTaskActionMenu(for taskID: UUID) {
        taskActionMenuTaskID = taskID
        showTaskActionMenu = true
    }

    private func prepareDeleteTask(taskID: UUID) {
        pendingDeleteTaskID = taskID
        showDeleteTaskAlert = true
    }

    private func confirmDeleteTask() {
        guard let pendingDeleteTaskID else { return }
        deleteTask(taskID: pendingDeleteTaskID)
        self.pendingDeleteTaskID = nil
        showDeleteTaskAlert = false
    }

    private func saveDailyPlan(taskID: UUID, minutesInput: String) -> String? {
        let planned = max(Int(minutesInput) ?? 0, 1)
        guard let task = tasks.first(where: { $0.id == taskID }) else {
            return nil
        }
        let assignments = dailyAssignments
        let existingAssignment = assignmentIndex(for: taskID).flatMap { assignments[$0] }
        let extraIfCompleted =
            (existingAssignment?.isCompleted == true)
            ? (existingAssignment?.plannedMinutes ?? 0) : 0
        let maxAllowed = max(task.remainingMinutes + extraIfCompleted, 0)

        if planned > maxAllowed {
            return "Planned \(planned) min exceeds remaining \(maxAllowed) min."
        }

        if let index = assignmentIndex(for: taskID) {
            let updatedAssignments = dailyAssignments
            if updatedAssignments[index].isCompleted {
                let newValue = task.completedMinutes - updatedAssignments[index].plannedMinutes
                task.completedMinutes = min(max(newValue, 0), task.totalMinutes)
                _ = appModel.recalculatePlan(
                    tasks: tasks, todayActualMinutes: 0, focusedTaskID: nil)
                updatedAssignments[index].isCompleted = false
                appModel.removeCompletionRecord(
                    task: task,
                    on: appModel.selectedDate,
                    existingRecords: dailyCompletionRecords
                )
            }
            updatedAssignments[index].plannedMinutes = planned
            try? modelContext.save()
        } else {
            modelContext.insert(
                DailyTaskAssignment(
                    task: task,
                    plannedMinutes: planned,
                    dayKey: appModel.selectedDate.dateKey
                )
            )
            try? modelContext.save()
        }

        appModel.refreshBingoStatus(
            dailyAssignments: latestDailyAssignments(),
            actionMessage: "🧩 Daily plan updated."
        )
        return nil
    }

    private func removeDailyTask(taskID: UUID) {
        guard let index = assignmentIndex(for: taskID) else { return }
        let assignmentToDelete = dailyAssignments[index]
        let taskName = tasks.first(where: { $0.id == taskID })?.title ?? "Task"

        if assignmentToDelete.isCompleted, let task = tasks.first(where: { $0.id == taskID }) {
            let newValue = task.completedMinutes - assignmentToDelete.plannedMinutes
            task.completedMinutes = min(max(newValue, 0), task.totalMinutes)
            _ = appModel.recalculatePlan(tasks: tasks, todayActualMinutes: 0, focusedTaskID: nil)
            appModel.removeCompletionRecord(
                task: task,
                on: appModel.selectedDate,
                existingRecords: dailyCompletionRecords
            )
        }

        modelContext.delete(assignmentToDelete)
        try? modelContext.save()
        appModel.refreshBingoStatus(
            dailyAssignments: latestDailyAssignments(),
            actionMessage: "🗂️ Removed \(taskName) from daily tasks."
        )
    }

    private func saveEditedTask(
        taskID: UUID, title: String, hours: Int, minutes: Int, deadline: Date
    ) {
        guard let task = tasks.first(where: { $0.id == taskID }) else { return }

        let total = max(hours * 60 + minutes, 1)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        task.title = trimmedTitle
        task.totalMinutes = total
        task.deadlineDate = deadline
        task.completedMinutes = min(task.completedMinutes, total)
        task.initialDays = appModel.calculateDaysLeft(from: Date(), to: deadline)

        _ = appModel.recalculatePlan(tasks: tasks, todayActualMinutes: 0, focusedTaskID: nil)
        try? modelContext.save()

        if let assignmentIndex = assignmentIndex(for: taskID) {
            let maxPlan = max(task.remainingMinutes, 1)
            dailyAssignments[assignmentIndex].plannedMinutes = min(
                dailyAssignments[assignmentIndex].plannedMinutes, maxPlan)
            try? modelContext.save()
        }

        showEditTaskSheet = false
        editingTaskID = nil
        appModel.refreshBingoStatus(
            dailyAssignments: latestDailyAssignments(),
            actionMessage: "✏️ Task updated."
        )
    }

    private func deleteTask(taskID: UUID) {
        if let task = tasks.first(where: { $0.id == taskID }) {
            modelContext.delete(task)
        }
        _ = appModel.recalculatePlan(tasks: tasks, todayActualMinutes: 0, focusedTaskID: nil)
        appModel.refreshBingoStatus(
            dailyAssignments: latestDailyAssignments(),
            actionMessage: "🗑️ Task deleted."
        )
    }
}
