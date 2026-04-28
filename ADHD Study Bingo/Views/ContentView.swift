import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var tasks: [StudyTask]
    @Query private var dailyTaskAssignments: [DailyTaskAssignment]

    @State private var hasLoadedFromStore: Bool = false

    private var currentDailyAssignments: [DailyTaskAssignment] {
        dailyTaskAssignments
            .filter { $0.dayKey == appModel.selectedDate.dateKey }
            .sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        @Bindable var appModel = appModel

        TabView {
            HomePageView(dailyAssignments: currentDailyAssignments)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            TaskListPageView(dailyAssignments: currentDailyAssignments)
                .tabItem {
                    Label("Tasks", systemImage: "list.bullet.rectangle")
                }
            HistoryPageView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
        }
        .onAppear {
            _ = appModel.recalculatePlan(
                tasks: tasks,
                todayActualMinutes: 0,
                focusedTaskID: nil
            )
            appModel.refreshBingoStatus(dailyAssignments: currentDailyAssignments)
        }
        .onChange(of: appModel.selectedDate) { _, _ in
            appModel.refreshBingoStatus(dailyAssignments: currentDailyAssignments)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            _ = appModel.recalculatePlan(
                tasks: tasks,
                todayActualMinutes: 0,
                focusedTaskID: nil
            )
            appModel.refreshBingoStatus(dailyAssignments: currentDailyAssignments)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [
                StudyTask.self,
                DailyTaskAssignment.self,
                DailyCompletionRecord.self,
            ],
            inMemory: true
        )
}
