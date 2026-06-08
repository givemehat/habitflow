import Foundation

public final class ExportManager: Sendable {
    public static let shared = ExportManager()
    
    private init() {}
    
    // Generates a comma-separated values (CSV) string representation of the habits and their logs.
    // Quotes are escaped to ensure compliance with CSV standards.
    public func generateCSVString(habits: [Habit]) -> String {
        var csv = "Habit ID,Name,Description,Category,Goal Type,Start Date,Weekly Target,Custom Weekdays,Completions Count,Log Dates,Reminder Enabled,Reminder Time,Reminder Weekdays\n"
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        
        for habit in habits {
            let id = habit.id.uuidString
            let name = escapeCSVField(habit.name)
            let desc = escapeCSVField(habit.habitDescription)
            let category = escapeCSVField(habit.categoryName)
            let goalType = habit.goalType.rawValue
            let startDate = dateFormatter.string(from: habit.startDate)
            let weeklyTarget = habit.weeklyTargetCount
            
            // Custom schedule days weekdays e.g. "Mon;Wed;Fri"
            let customDays = habit.customScheduleDays.map { dayNum -> String in
                switch dayNum {
                case 1: return "Sun"
                case 2: return "Mon"
                case 3: return "Tue"
                case 4: return "Wed"
                case 5: return "Thu"
                case 6: return "Fri"
                case 7: return "Sat"
                default: return ""
                }
            }.filter { !$0.isEmpty }.joined(separator: ";")
            let customDaysEscaped = escapeCSVField(customDays)
            
            let completionsCount = habit.logs.count
            
            // Log dates in semicolon-separated format
            let logDates = habit.logs.map { dateFormatter.string(from: $0.date) }.joined(separator: ";")
            let logDatesEscaped = escapeCSVField(logDates)
            
            // Reminder settings
            let reminderEnabled = habit.reminderEnabled ? "true" : "false"
            let reminderTime = String(format: "%02d:%02d", habit.reminderHour, habit.reminderMinute)
            let reminderWeekdays = habit.reminderDays.map { dayNum -> String in
                switch dayNum {
                case 1: return "Sun"
                case 2: return "Mon"
                case 3: return "Tue"
                case 4: return "Wed"
                case 5: return "Thu"
                case 6: return "Fri"
                case 7: return "Sat"
                default: return ""
                }
            }.filter { !$0.isEmpty }.joined(separator: ";")
            let reminderWeekdaysEscaped = escapeCSVField(reminderWeekdays)
            
            csv += "\(id),\(name),\(desc),\(category),\(goalType),\(startDate),\(weeklyTarget),\(customDaysEscaped),\(completionsCount),\(logDatesEscaped),\(reminderEnabled),\(reminderTime),\(reminderWeekdaysEscaped)\n"
        }
        
        return csv
    }
    
    private func escapeCSVField(_ field: String) -> String {
        var escaped = field
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") || escaped.contains(";") {
            escaped = escaped.replacingOccurrences(of: "\"", with: "\"\"")
            escaped = "\"\(escaped)\""
        }
        return escaped
    }
}
