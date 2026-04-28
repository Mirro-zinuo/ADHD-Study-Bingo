import SwiftUI
import SwiftData

struct HistoryPageView: View {
    @Query private var storedCompletionRecords: [DailyCompletionRecord]

    private static let historyTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private var sortedHistoryDayKeys: [String] {
        completionHistoryByDate.keys.sorted { lhs, rhs in
            guard let leftDate = Date.fromDateKey(lhs),
                  let rightDate = Date.fromDateKey(rhs) else {
                return lhs > rhs
            }
            return leftDate > rightDate
        }
    }

    private var completionHistoryByDate: [String: [DailyCompletionRecord]] {
        Dictionary(grouping: storedCompletionRecords, by: \.dayKey)
    }

    var body: some View {
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

                                if let records = completionHistoryByDate[dayKey] {
                                    ForEach(records.sorted(by: { $0.completedAt > $1.completedAt })) { record in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(record.task?.title ?? "Task")
                                                    .font(.subheadline.weight(.semibold))
                                                Text("Completed \(record.completedMinutes) min")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Text(Self.historyTimeFormatter.string(from: record.completedAt))
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
}
