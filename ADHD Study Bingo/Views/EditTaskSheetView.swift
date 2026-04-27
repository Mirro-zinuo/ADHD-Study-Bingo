import SwiftUI

struct EditTaskSheetView: View {
    @State private var title: String
    @State private var hours: Int
    @State private var minutes: Int
    @State private var deadline: Date
    let onCommit: (String, Int, Int, Date) -> Void
    let onCancel: () -> Void

    init(
        initialTitle: String,
        initialHours: Int,
        initialMinutes: Int,
        initialDeadline: Date,
        onCommit: @escaping (String, Int, Int, Date) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _title = State(initialValue: initialTitle)
        _hours = State(initialValue: initialHours)
        _minutes = State(initialValue: initialMinutes)
        _deadline = State(initialValue: initialDeadline)
        self.onCommit = onCommit
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Edit Task Info") {
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
            .navigationTitle("Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        onCommit(trimmed, hours, minutes, deadline)
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
