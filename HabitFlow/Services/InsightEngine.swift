import Foundation

public struct HabitInsight: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let detail: String
    public let systemIcon: String
    public let relevanceScore: Double // Higher score means higher priority/relevance
}

public final class InsightEngine: Sendable {
    public static let shared = InsightEngine()
    
    private init() {}
    
    // Generates insights based on SwiftData habits and logs
    public func generateInsights(from habits: [Habit]) -> [HabitInsight] {
        var insights: [HabitInsight] = []
        
        guard !habits.isEmpty else {
            return [
                HabitInsight(
                    title: "Welcome to HabitFlow!",
                    detail: "Start checking off habits to see local productivity insights generated here.",
                    systemIcon: "sparkles",
                    relevanceScore: 1.0
                )
            ]
        }
        
        let allLogs = habits.flatMap { $0.logs }
        guard !allLogs.isEmpty else {
            return [
                HabitInsight(
                    title: "No completion logs yet",
                    detail: "Complete a habit to unlock analytical insights.",
                    systemIcon: "chart.bar.xaxis",
                    relevanceScore: 1.0
                )
            ]
        }
        
        let calendar = Calendar.current
        
        // 1. Analyze Weekday vs Weekend completion for categories
        let categories = Set(habits.map { $0.categoryName })
        for category in categories {
            let categoryHabits = habits.filter { $0.categoryName == category }
            let categoryLogs = categoryHabits.flatMap { $0.logs }
            
            if categoryLogs.count >= 5 {
                var weekdayScheduled: Double = 0
                var weekdayCompleted: Double = 0
                var weekendScheduled: Double = 0
                var weekendCompleted: Double = 0
                
                // Inspect last 30 days
                let today = Date()
                for i in 0..<30 {
                    guard let checkDate = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
                    let isWeekend = calendar.isDateInWeekend(checkDate)
                    
                    for habit in categoryHabits {
                        if habit.isScheduled(on: checkDate) {
                            if isWeekend {
                                weekendScheduled += 1
                                if habit.isCompleted(on: checkDate) {
                                    weekendCompleted += 1
                                }
                            } else {
                                weekdayScheduled += 1
                                if habit.isCompleted(on: checkDate) {
                                    weekdayCompleted += 1
                                }
                            }
                        }
                    }
                }
                
                let weekdayRate = weekdayScheduled > 0 ? (weekdayCompleted / weekdayScheduled) : 0.0
                let weekendRate = weekendScheduled > 0 ? (weekendCompleted / weekendScheduled) : 0.0
                let diff = abs(weekdayRate - weekendRate)
                
                if diff >= 0.15 { // 15% difference minimum
                    let percent = Int(diff * 100)
                    if weekdayRate > weekendRate {
                        insights.append(HabitInsight(
                            title: "\(category) Weekday Bias",
                            detail: "You complete \(category.lowercased()) habits \(percent)% more often on weekdays compared to weekends.",
                            systemIcon: "desktopcomputer",
                            relevanceScore: 0.8 + diff
                        ))
                    } else {
                        insights.append(HabitInsight(
                            title: "\(category) Weekend Boost",
                            detail: "You complete \(category.lowercased()) habits \(percent)% more often on weekends compared to weekdays.",
                            systemIcon: "sun.max.fill",
                            relevanceScore: 0.8 + diff
                        ))
                    }
                }
            }
        }
        
        // 2. Best Productivity Day
        var dayCompletionCounts: [Int: Int] = [:] // Weekday component -> Count
        for log in allLogs {
            let weekday = calendar.component(.weekday, from: log.date)
            dayCompletionCounts[weekday, default: 0] += 1
        }
        
        if let bestDayEntry = dayCompletionCounts.max(by: { $0.value < $1.value }) {
            let formatter = DateFormatter()
            let weekdayName = formatter.standaloneWeekdaySymbols[bestDayEntry.key - 1]
            insights.append(HabitInsight(
                title: "Peak Performance Day",
                detail: "Your best productivity day is \(weekdayName), with \(bestDayEntry.value) total completions recorded.",
                systemIcon: "bolt.fill",
                relevanceScore: 0.9
            ))
        }
        
        // 3. Time-of-day Drops (e.g. Fitness completion drops after 8 PM)
        let fitnessHabits = habits.filter { $0.categoryName.lowercased().contains("fitness") || $0.categoryName.lowercased().contains("health") }
        let fitnessLogs = fitnessHabits.flatMap { $0.logs }
        if fitnessLogs.count >= 4 {
            let eveningLogs = fitnessLogs.filter { log in
                let hour = calendar.component(.hour, from: log.date)
                return hour >= 20 || hour < 4 // 8 PM to 4 AM
            }
            let daytimeLogsCount = fitnessLogs.count - eveningLogs.count
            
            if daytimeLogsCount > eveningLogs.count * 2 {
                insights.append(HabitInsight(
                    title: "Evening Energy Dip",
                    detail: "Fitness and health completions drop significantly after 8:00 PM. Try scheduling them earlier in the day.",
                    systemIcon: "moon.fill",
                    relevanceScore: 0.85
                ))
            }
        }
        
        // 4. Most consistent habit (highest active streak)
        if let topHabit = habits.max(by: { $0.calculateCurrentStreak() < $1.calculateCurrentStreak() }) {
            let streak = topHabit.calculateCurrentStreak()
            if streak >= 3 {
                insights.append(HabitInsight(
                    title: "Amazing Consistency",
                    detail: "You are on a \(streak)-day streak for \"\(topHabit.name)\"! Keep the momentum going.",
                    systemIcon: "flame.fill",
                    relevanceScore: 0.95
                ))
            }
        }
        
        // 5. Habits needing attention (Most missed habit in the last 14 days)
        var lowestCompletionHabit: Habit? = nil
        var lowestRate: Double = 1.0
        let today = Date()
        
        for habit in habits {
            var scheduled = 0
            var completed = 0
            
            for i in 0..<14 {
                guard let checkDate = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
                if habit.isScheduled(on: checkDate) {
                    scheduled += 1
                    if habit.isCompleted(on: checkDate) {
                        completed += 1
                    }
                }
            }
            
            if scheduled >= 4 {
                let rate = Double(completed) / Double(scheduled)
                if rate < lowestRate {
                    lowestRate = rate
                    lowestCompletionHabit = habit
                }
            }
        }
        
        if let focusHabit = lowestCompletionHabit, lowestRate <= 0.5 {
            let ratePercent = Int(lowestRate * 100)
            insights.append(HabitInsight(
                title: "Needs Attention",
                detail: "Your completion rate for \"\(focusHabit.name)\" is only \(ratePercent)% over the last two weeks. Small steps build consistency!",
                systemIcon: "exclamationmark.triangle.fill",
                relevanceScore: 0.75 + (1.0 - lowestRate)
            ))
        }
        
        // Sort by relevance score descending
        return insights.sorted(by: { $0.relevanceScore > $1.relevanceScore })
    }
}
