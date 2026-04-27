import Foundation

struct DailyPlanDraft: Identifiable {
    let taskID: UUID
    let minutesText: String
    var id: UUID { taskID }
}
