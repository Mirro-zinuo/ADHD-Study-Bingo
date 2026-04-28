import SwiftUI

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
