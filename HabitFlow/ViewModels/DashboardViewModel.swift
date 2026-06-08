import Foundation
import SwiftUI
import Observation

@Observable
public final class DashboardViewModel: Sendable {
    public init() {}
    
    // Total habits count
    public func totalHabits(from habits: [Habit]) -> Int {
        habits.count
    }
    
    // Scheduled for today
    public func todayHabits(from habits: [Habit]) -> [Habit] {
        let today = Date()
        return habits.filter { $0.isScheduled(on: today) }
    }
    
    // Completed today
    public func todayCompletedHabits(from habits: [Habit]) -> [Habit] {
        let today = Date()
        return todayHabits(from: habits).filter { $0.isCompleted(on: today) }
    }
    
    // Completion rate today
    public func todayCompletionRate(from habits: [Habit]) -> Double {
        let todayList = todayHabits(from: habits)
        guard !todayList.isEmpty else { return 0.0 }
        let completed = todayList.filter { $0.isCompleted(on: Date()) }.count
        return Double(completed) / Double(todayList.count)
    }
    
    // Longest streak across all habits
    public func longestStreakOverall(from habits: [Habit]) -> Int {
        habits.map { $0.calculateLongestStreak() }.max() ?? 0
    }
    
    // Sum of all current active streaks
    public func activeStreaksSum(from habits: [Habit]) -> Int {
        habits.map { $0.calculateCurrentStreak() }.reduce(0, +)
    }
    
    // Highest current streak among all habits
    public func highestCurrentStreak(from habits: [Habit]) -> Int {
        habits.map { $0.calculateCurrentStreak() }.max() ?? 0
    }
    
    // Weekly score: count of completions in the last 7 days (including today)
    public func weeklyScore(from habits: [Habit]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today) else { return 0 }
        
        var totalCompletions = 0
        for habit in habits {
            totalCompletions += habit.logs.filter { log in
                let logDay = calendar.startOfDay(for: log.date)
                return logDay >= sevenDaysAgo && logDay <= today
            }.count
        }
        return totalCompletions
    }
    
    // Monthly score: count of completions in the current calendar month
    public func monthlyScore(from habits: [Habit]) -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        var totalCompletions = 0
        for habit in habits {
            totalCompletions += habit.logs.filter { log in
                calendar.isDate(log.date, equalTo: now, toGranularity: .month)
            }.count
        }
        return totalCompletions
    }
    
    // Weekly completion progress chart data structure
    public struct DayCompletion: Identifiable {
        public let id = UUID()
        public let dayName: String
        public let date: Date
        public let completionCount: Int
    }
    
    public func weeklyCompletionData(from habits: [Habit]) -> [DayCompletion] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var data: [DayCompletion] = []
        
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // e.g. Mon, Tue
        
        for i in (0...6).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let startOfTargetDay = calendar.startOfDay(for: date)
            
            let completions = habits.flatMap { $0.logs }.filter { log in
                calendar.isDate(log.date, inSameDayAs: startOfTargetDay)
            }.count
            
            data.append(DayCompletion(dayName: formatter.string(from: date), date: date, completionCount: completions))
        }
        
        return data
    }
    
    // Category distribution chart data structure
    public struct CategoryDistribution: Identifiable {
        public let id = UUID()
        public let categoryName: String
        public let habitCount: Int
        public let colorHex: String
    }
    
    public func categoryDistribution(from habits: [Habit]) -> [CategoryDistribution] {
        var counts: [String: Int] = [:]
        var colors: [String: String] = [:]
        
        for habit in habits {
            counts[habit.categoryName, default: 0] += 1
            if colors[habit.categoryName] == nil {
                colors[habit.categoryName] = habit.colorHex
            }
        }
        
        return counts.map { (key, value) in
            CategoryDistribution(
                categoryName: key,
                habitCount: value,
                colorHex: colors[key] ?? "#8E8E93"
            )
        }.sorted(by: { $0.habitCount > $1.habitCount })
    }
}
