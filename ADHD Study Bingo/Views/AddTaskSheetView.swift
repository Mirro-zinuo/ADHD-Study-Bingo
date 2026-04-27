import SwiftUI
import SwiftData

struct AddTaskSheetView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var hours: Int = 1
    @State private var minutes: Int = 0
    @State private var deadline: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
    @Query private var storedTasks: [StudyTask]

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Info") {
                    TextField("Task Name", text: $title)
                    HStack(spacing: 12) {
                        Picker("Hours", selection: $hours) {
                            ForEach(0..<24, id: \.self) { value in
                                Text("\(value) h").tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity, maxHeight: 110)

                        Picker("Minutes", selection: $minutes) {
                            ForEach(0..<60, id: \.self) { value in
                                Text("\(value) min").tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity, maxHeight: 110)
                    }
                    DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                }
            }
            .navigationTitle("Add Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        addTask(title: trimmed, hours: hours, minutes: minutes, deadline: deadline)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func addTask(title: String, hours: Int, minutes: Int, deadline: Date) {
        let total = max(hours * 60 + minutes, 1)

        let newTask = StudyTask(
            title: title,
            totalMinutes: total,
            completedMinutes: 0,
            deadlineDate: deadline
        )

        modelContext.insert(newTask)
        _ = appModel.recalculatePlan(tasks: storedTasks, todayActualMinutes: 0, focusedTaskID: nil)
        try? modelContext.save()
    }
}
