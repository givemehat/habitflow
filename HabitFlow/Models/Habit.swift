import Foundation
import SwiftData

public enum GoalType: String, Codable, CaseIterable, Sendable {
    case daily = "Daily"
    case weekly = "Weekly"
    case alternateDays = "Alternate Days"
    case customSchedule = "Custom Schedule"
}

@Model
public final class Habit: Sendable {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var habitDescription: String
    public var categoryName: String
    public var icon: String
    public var colorHex: String
    public var goalTypeRaw: String
    public var customScheduleDaysRaw: String // "1,3,5" -> weekdays list (1=Sunday, 2=Monday, ..., 7=Saturday)
    public var weeklyTargetCount: Int
    public var startDate: Date
    
    // Custom Reminder Fields
    public var reminderEnabled: Bool
    public var reminderHour: Int
    public var reminderMinute: Int
    public var reminderDaysRaw: String // "1,2,3" -> weekdays list (1=Sunday, 2=Monday...)
    
    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    public var logs: [HabitLog] = []
    
    public init(
        id: UUID = UUID(),
        name: String,
        habitDescription: String = "",
        categoryName: String,
        icon: String = "checkmark.circle",
        colorHex: String = "#0A84FF",
        goalType: GoalType = .daily,
        customScheduleDays: [Int] = [],
        weeklyTargetCount: Int = 1,
        startDate: Date = Date(),
        reminderEnabled: Bool = false,
        reminderHour: Int = 9,
        reminderMinute: Int = 0,
        reminderDays: [Int] = []
    ) {
        self.id = id
        self.name = name
        self.habitDescription = habitDescription
        self.categoryName = categoryName
        self.icon = icon
        self.colorHex = colorHex
        self.goalTypeRaw = goalType.rawValue
        self.customScheduleDaysRaw = customScheduleDays.map(String.init).joined(separator: ",")
        self.weeklyTargetCount = weeklyTargetCount
        self.startDate = Calendar.current.startOfDay(for: startDate)
        self.reminderEnabled = reminderEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.reminderDaysRaw = reminderDays.map(String.init).joined(separator: ",")
        self.logs = []
    }
    
    public var goalType: GoalType {
        get { GoalType(rawValue: goalTypeRaw) ?? .daily }
        set { goalTypeRaw = newValue.rawValue }
    }
    
    public var customScheduleDays: [Int] {
        get {
            customScheduleDaysRaw.split(separator: ",")
                .compactMap { Int($0) }
        }
        set {
            customScheduleDaysRaw = newValue.map(String.init).joined(separator: ",")
        }
    }
    
    public var reminderDays: [Int] {
        get {
            reminderDaysRaw.split(separator: ",")
                .compactMap { Int($0) }
        }
        set {
            reminderDaysRaw = newValue.map(String.init).joined(separator: ",")
        }
    }
    
    // Checks if the habit has a task required on a specific date
    public func isScheduled(on date: Date) -> Bool {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        // Cannot be scheduled before start date
        if targetDate < startDate {
            return false
        }
        
        switch goalType {
        case .daily:
            return true
        case .weekly:
            // Weekly habits are active overall, can be checked off any day
            return true
        case .alternateDays:
            let components = calendar.dateComponents([.day], from: startDate, to: targetDate)
            guard let days = components.day else { return false }
            return days % 2 == 0
        case .customSchedule:
            let weekday = calendar.component(.weekday, from: targetDate)
            return customScheduleDays.contains(weekday)
        }
    }
    
    // Checks if the habit was completed on a specific date
    public func isCompleted(on date: Date) -> Bool {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        return logs.contains { log in
            calendar.isDate(log.date, inSameDayAs: targetDay)
        }
    }
    
    // Helper to fetch completion log for a specific date
    public func log(on date: Date) -> HabitLog? {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        return logs.first { log in
            calendar.isDate(log.date, inSameDayAs: targetDay)
        }
    }
    
    // Calculates current streak based on schedule
    public func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Find all completed dates, sorted descending
        let completedDates = logs.map { calendar.startOfDay(for: $0.date) }
            .sorted(by: >)
        
        if completedDates.isEmpty {
            return 0
        }
        
        // Let's trace backwards day-by-day
        var currentDate = today
        var streak = 0
        var isFirstCheck = true
        
        // If the habit is not scheduled for today and today hasn't been logged,
        // we start checking from yesterday.
        if !isScheduled(on: today) && !completedDates.contains(today) {
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
                currentDate = yesterday
            }
        }
        
        while true {
            // Safety break: don't look back before start date
            if currentDate < startDate {
                break
            }
            
            // If the habit is scheduled on currentDate
            if isScheduled(on: currentDate) {
                if completedDates.contains(currentDate) {
                    streak += 1
                } else {
                    // If it was the first check (today) and today is not completed, we can skip it
                    // and check yesterday, provided yesterday was completed.
                    if isFirstCheck && currentDate == today {
                        // Keep going, don't break yet
                    } else {
                        // Missed a scheduled day, streak breaks
                        break
                    }
                }
            }
            
            isFirstCheck = false
            guard let nextDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return streak
    }
    
    // Calculates longest streak in history
    public func calculateLongestStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // We need to trace from startDate to today day-by-day and find the maximum contiguous streak
        guard startDate <= today else { return 0 }
        
        var tempStreak = 0
        var maxStreak = 0
        
        var currentDate = startDate
        let completedDates = Set(logs.map { calendar.startOfDay(for: $0.date) })
        
        while currentDate <= today {
            if isScheduled(on: currentDate) {
                if completedDates.contains(currentDate) {
                    tempStreak += 1
                    if tempStreak > maxStreak {
                        maxStreak = tempStreak
                    }
                } else {
                    // If it's today and not completed yet, we don't break the streak for longest streak check
                    if calendar.isDateInToday(currentDate) {
                        // do nothing, don't break yet
                    } else {
                        tempStreak = 0
                    }
                }
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return maxStreak
    }
}
