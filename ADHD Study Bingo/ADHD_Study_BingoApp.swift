//
//  ADHD_Study_BingoApp.swift
//  ADHD Study Bingo
//
//  Created by Mirro on 4/25/26.
//

import SwiftUI
import SwiftData

@main
struct ADHD_Study_BingoApp: App {
    private static let hasSeededInitialTasksKey = "hasSeededInitialTasks"

    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StudyTask.self,
            DailyTaskAssignment.self,
            DailyCompletionRecord.self
        ])

        do {
            return try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
    
    @State private var appModel : AppModel
    
    init() {
        let modelContext = Self.sharedModelContainer.mainContext
        Self.seedInitialTasksIfNeeded(in: modelContext)
        appModel = .init(modelContext: modelContext)
    }

    private static func seedInitialTasksIfNeeded(in modelContext: ModelContext) {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: hasSeededInitialTasksKey) == false else { return }

        do {
            let samples = [
                StudyTask(title: "CS Project", totalMinutes: 300, completedMinutes: 0, deadlineDate: Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()),
                StudyTask(title: "History Essay", totalMinutes: 180, completedMinutes: 0, deadlineDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()),
                StudyTask(title: "Math Review", totalMinutes: 240, completedMinutes: 0, deadlineDate: Calendar.current.date(byAdding: .day, value: 6, to: Date()) ?? Date()),
                StudyTask(title: "SAT Review", totalMinutes: 260, completedMinutes: 0, deadlineDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()),
                StudyTask(title: "DP Practice", totalMinutes: 200, completedMinutes: 0, deadlineDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()),
                StudyTask(title: "Data Preview", totalMinutes: 160, completedMinutes: 0, deadlineDate: Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()),
                StudyTask(title: "Physics Review", totalMinutes: 220, completedMinutes: 0, deadlineDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()),
                StudyTask(title: "English Workbook", totalMinutes: 190, completedMinutes: 0, deadlineDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()),
                StudyTask(title: "Codeforces", totalMinutes: 170, completedMinutes: 0, deadlineDate: Calendar.current.date(byAdding: .day, value: 6, to: Date()) ?? Date())
            ]

            for task in samples {
                modelContext.insert(task)
            }

            try modelContext.save()
            defaults.set(true, forKey: hasSeededInitialTasksKey)
        } catch {
            assertionFailure("Failed seeding initial tasks: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
        .modelContainer(Self.sharedModelContainer)
    }
}
