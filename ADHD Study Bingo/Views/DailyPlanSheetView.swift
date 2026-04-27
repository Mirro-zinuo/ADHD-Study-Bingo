import SwiftUI

struct DailyPlanSheetView: View {
    @State private var minutesInput: String
    let onAttemptSave: (String) -> Bool
    let onCancel: () -> Void

    init(
        initialMinutes: String,
        onAttemptSave: @escaping (String) -> Bool,
        onCancel: @escaping () -> Void
    ) {
        _minutesInput = State(initialValue: initialMinutes)
        self.onAttemptSave = onAttemptSave
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Planned Time") {
                    TextField("Minutes", text: $minutesInput)
                }
            }
            .navigationTitle("Add to Daily Tasks")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        _ = onAttemptSave(minutesInput)
                    }
                }
            }
        }
    }
}
