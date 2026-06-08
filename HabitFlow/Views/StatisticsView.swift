import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query private var habits: [Habit]
    @State private var timeRange: ReportRange = .monthly
    
    enum ReportRange: String, CaseIterable, Identifiable {
        case weekly = "Weekly Report"
        case monthly = "Monthly Report"
        case yearly = "Yearly Report"
        
        public var id: String { self.rawValue }
        
        var daysCount: Int {
            switch self {
            case .weekly: return 7
            case .monthly: return 30
            case .yearly: return 365
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Analytics & Reports")
                            .font(.system(size: 28, weight: .bold))
                        Text("Detailed performance metrics and completion trends")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    Picker("Time Range", selection: $timeRange) {
                        ForEach(ReportRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 320)
                }
                
                if habits.isEmpty {
                    ContentUnavailableView(
                        "No Data to Analyze",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Statistics will appear here once you add habits and log completions.")
                    )
                    .frame(minHeight: 350)
                } else {
                    let report = generateReport(days: timeRange.daysCount)
                    
                    // Stats Summary row
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 14),
                        GridItem(.flexible(), spacing: 14),
                        GridItem(.flexible(), spacing: 14),
                        GridItem(.flexible(), spacing: 14)
                    ]) {
                        StatCard(
                            title: "Completion Rate",
                            value: "\(Int(report.completionRate * 100))%",
                            subtitle: "Average success rate",
                            systemIcon: "square.grid.3x3.fill",
                            iconColor: .green
                        )
                        
                        StatCard(
                            title: "Best Day",
                            value: report.bestDay,
                            subtitle: "Highest completed count",
                            systemIcon: "hand.thumbsup.fill",
                            iconColor: .blue
                        )
                        
                        StatCard(
                            title: "Worst Day",
                            value: report.worstDay,
                            subtitle: "Lowest completed count",
                            systemIcon: "hand.thumbsdown.fill",
                            iconColor: .red
                        )
                        
                        StatCard(
                            title: "Total Completions",
                            value: "\(report.totalCompletions)",
                            subtitle: "Logs in this period",
                            systemIcon: "checkmark.seal.fill",
                            iconColor: .purple
                        )
                    }
                    
                    // Habits Insights Row
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Most Consistent Habit")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(report.mostConsistentHabit)
                                .font(.title3)
                                .bold()
                                .foregroundColor(.primary)
                            Text("Highest relative completion rate")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Most Missed Habit")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(report.mostMissedHabit)
                                .font(.title3)
                                .bold()
                                .foregroundColor(.red)
                            Text("Lowest relative completion rate")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                    }
                    
                    // Historical Trend Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Completion Rate Trend")
                            .font(.title3)
                            .bold()
                        
                        Chart {
                            ForEach(report.trendData) { day in
                                LineMark(
                                    x: .value("Date", day.date, unit: .day),
                                    y: .value("Rate", day.rate * 100)
                                )
                                .foregroundStyle(Color.blue.gradient)
                                .interpolationMethod(.cardinal)
                                
                                AreaMark(
                                    x: .value("Date", day.date, unit: .day),
                                    y: .value("Rate", day.rate * 100)
                                )
                                .foregroundStyle(Color.blue.opacity(0.12).gradient)
                                .interpolationMethod(.cardinal)
                            }
                        }
                        .frame(height: 220)
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                    }
                    .padding(14)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                }
            }
            .padding(20)
        }
    }
    
    // Struct to hold processed stats
    struct ReportStats {
        let completionRate: Double
        let bestDay: String
        let worstDay: String
        let totalCompletions: Int
        let mostConsistentHabit: String
        let mostMissedHabit: String
        let trendData: [DailyTrend]
    }
    
    struct DailyTrend: Identifiable {
        let id = UUID()
        let date: Date
        let rate: Double
    }
    
    private func generateReport(days: Int) -> ReportStats {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let rangeStartDate = calendar.date(byAdding: .day, value: -(days - 1), to: today) else {
            return ReportStats(completionRate: 0, bestDay: "N/A", worstDay: "N/A", totalCompletions: 0, mostConsistentHabit: "N/A", mostMissedHabit: "N/A", trendData: [])
        }
        
        var totalScheduled = 0
        var totalCompleted = 0
        var weekdayCounts: [Int: Int] = [:] // Weekday -> Completed
        var weekdayScheduled: [Int: Int] = [:] // Weekday -> Scheduled
        
        var trendData: [DailyTrend] = []
        
        // Loop date-by-date in range
        for i in 0..<days {
            guard let checkDate = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let weekday = calendar.component(.weekday, from: checkDate)
            
            var dailyScheduled = 0
            var dailyCompleted = 0
            
            for habit in habits {
                if habit.isScheduled(on: checkDate) {
                    dailyScheduled += 1
                    totalScheduled += 1
                    weekdayScheduled[weekday, default: 0] += 1
                    
                    if habit.isCompleted(on: checkDate) {
                        dailyCompleted += 1
                        totalCompleted += 1
                        weekdayCounts[weekday, default: 0] += 1
                    }
                }
            }
            
            let dailyRate = dailyScheduled > 0 ? (Double(dailyCompleted) / Double(dailyScheduled)) : 0.0
            trendData.append(DailyTrend(date: checkDate, rate: dailyRate))
        }
        
        // Sort trend ascending by date
        trendData.sort(by: { $0.date < $1.date })
        
        // Find best and worst day of week (e.g. Tuesday is best)
        let formatter = DateFormatter()
        let weekdays = formatter.standaloneWeekdaySymbols ?? []
        
        var bestDayName = "N/A"
        var bestDayRate: Double = -1.0
        
        var worstDayName = "N/A"
        var worstDayRate: Double = 2.0
        
        for w in 1...7 {
            let scheduled = weekdayScheduled[w] ?? 0
            let completed = weekdayCounts[w] ?? 0
            guard scheduled > 0 else { continue }
            let rate = Double(completed) / Double(scheduled)
            
            let dayName = weekdays[w - 1]
            
            if rate > bestDayRate {
                bestDayRate = rate
                bestDayName = dayName
            }
            if rate < worstDayRate {
                worstDayRate = rate
                worstDayName = dayName
            }
        }
        
        // Find most consistent/missed habit based on completion rate in this window
        var habitRates: [(Habit, Double)] = []
        for habit in habits {
            var scheduled = 0
            var completed = 0
            
            for i in 0..<days {
                guard let checkDate = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
                if habit.isScheduled(on: checkDate) {
                    scheduled += 1
                    if habit.isCompleted(on: checkDate) {
                        completed += 1
                    }
                }
            }
            
            if scheduled > 0 {
                let rate = Double(completed) / Double(scheduled)
                habitRates.append((habit, rate))
            }
        }
        
        let mostConsistent = habitRates.max(by: { $0.1 < $1.1 })?.0.name ?? "None"
        let mostMissed = habitRates.min(by: { $0.1 < $1.1 })?.0.name ?? "None"
        
        let averageRate = totalScheduled > 0 ? (Double(totalCompleted) / Double(totalScheduled)) : 0.0
        
        return ReportStats(
            completionRate: averageRate,
            bestDay: bestDayName,
            worstDay: worstDayName,
            totalCompletions: totalCompleted,
            mostConsistentHabit: mostConsistent,
            mostMissedHabit: mostMissed,
            trendData: trendData
        )
    }
}
