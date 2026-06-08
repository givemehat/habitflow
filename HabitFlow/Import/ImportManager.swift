import Foundation
import SwiftData

public final class ImportManager: Sendable {
    public static let shared = ImportManager()
    
    private init() {}
    
    // Parses a CSV string and imports habits/logs into ModelContext
    public func importCSV(string: String, into modelContext: ModelContext, mergeMode: String = "Merge") -> Bool {
        let lines = string.components(separatedBy: .newlines)
        guard lines.count > 1 else { return false }
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        
        // Fetch existing habits
        let descriptor = FetchDescriptor<Habit>()
        let existingHabits = (try? modelContext.fetch(descriptor)) ?? []
        
        // Skip header
        for line in lines.dropFirst() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }
            
            let fields = parseCSVLine(trimmedLine)
            guard fields.count >= 6 else { continue }
            
            let idStr = fields[0]
            let name = fields[1]
            let desc = fields[2]
            let category = fields[3]
            let goalTypeRaw = fields[4]
            let startDateStr = fields[5]
            let weeklyTarget = fields.count > 6 ? (Int(fields[6]) ?? 1) : 1
            let customWeekdaysStr = fields.count > 7 ? fields[7] : ""
            let logDatesStr = fields.count > 9 ? fields[9] : ""
            
            // Reminders parsing
            let reminderEnabled = fields.count > 10 ? (fields[10].lowercased() == "true") : false
            
            var reminderHour = 9
            var reminderMinute = 0
            if fields.count > 11 {
                let timeParts = fields[11].split(separator: ":")
                if timeParts.count == 2,
                   let h = Int(timeParts[0]),
                   let m = Int(timeParts[1]) {
                    reminderHour = h
                    reminderMinute = m
                }
            }
            
            var reminderWeekdays: [Int] = []
            if fields.count > 12 {
                let reminderComponents = fields[12].split(separator: ";")
                for comp in reminderComponents {
                    switch comp.lowercased() {
                    case "sun": reminderWeekdays.append(1)
                    case "mon": reminderWeekdays.append(2)
                    case "tue": reminderWeekdays.append(3)
                    case "wed": reminderWeekdays.append(4)
                    case "thu": reminderWeekdays.append(5)
                    case "fri": reminderWeekdays.append(6)
                    case "sat": reminderWeekdays.append(7)
                    default: break
                    }
                }
            }
            
            guard let id = UUID(uuidString: idStr),
                  let startDate = dateFormatter.date(from: startDateStr) else { continue }
            
            let goalType = GoalType(rawValue: goalTypeRaw) ?? .daily
            
            // Parse custom weekdays (e.g. "Mon;Wed;Fri")
            var customDays: [Int] = []
            let dayComponents = customWeekdaysStr.split(separator: ";")
            for comp in dayComponents {
                switch comp.lowercased() {
                case "sun": customDays.append(1)
                case "mon": customDays.append(2)
                case "tue": customDays.append(3)
                case "wed": customDays.append(4)
                case "thu": customDays.append(5)
                case "fri": customDays.append(6)
                case "sat": customDays.append(7)
                default: break
                }
            }
            
            // Check duplicates
            let duplicate = existingHabits.first { $0.id == id || $0.name.lowercased() == name.lowercased() }
            let habitToUpdate: Habit
            
            if let existing = duplicate {
                if mergeMode == "Overwrite" {
                    existing.name = name
                    existing.habitDescription = desc
                    existing.categoryName = category
                    existing.goalTypeRaw = goalType.rawValue
                    existing.startDate = startDate
                    existing.weeklyTargetCount = weeklyTarget
                    existing.customScheduleDays = customDays
                    
                    existing.reminderEnabled = reminderEnabled
                    existing.reminderHour = reminderHour
                    existing.reminderMinute = reminderMinute
                    existing.reminderDays = reminderWeekdays
                }
                habitToUpdate = existing
            } else {
                let newHabit = Habit(
                    id: id,
                    name: name,
                    habitDescription: desc,
                    categoryName: category,
                    weeklyTargetCount: weeklyTarget,
                    startDate: startDate,
                    reminderEnabled: reminderEnabled,
                    reminderHour: reminderHour,
                    reminderMinute: reminderMinute,
                    reminderDays: reminderWeekdays
                )
                newHabit.goalTypeRaw = goalType.rawValue
                newHabit.customScheduleDays = customDays
                modelContext.insert(newHabit)
                habitToUpdate = newHabit
            }
            
            // Parse log dates (e.g. "2026-06-01;2026-06-03")
            let logComponents = logDatesStr.split(separator: ";")
            let calendar = Calendar.current
            
            for logDateStr in logComponents {
                guard let date = dateFormatter.date(from: String(logDateStr)) else { continue }
                
                let alreadyLogged = habitToUpdate.logs.contains { calendar.isDate($0.date, inSameDayAs: date) }
                if !alreadyLogged {
                    let log = HabitLog(id: UUID(), date: date, notes: "Imported", habit: habitToUpdate)
                    habitToUpdate.logs.append(log)
                    modelContext.insert(log)
                }
            }
        }
        
        try? modelContext.save()
        return true
    }
    
    // A robust CSV line splitter that handles quotes properly
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        let chars = Array(line)
        var i = 0
        while i < chars.count {
            let char = chars[i]
            
            if char == "\"" {
                if insideQuotes {
                    // Check if escaped quote
                    if i + 1 < chars.count && chars[i+1] == "\"" {
                        currentField.append("\"")
                        i += 1 // skip next quote
                    } else {
                        insideQuotes = false
                    }
                } else {
                    insideQuotes = true
                }
            } else if char == "," {
                if insideQuotes {
                    currentField.append(char)
                } else {
                    fields.append(currentField)
                    currentField = ""
                }
            } else {
                currentField.append(char)
            }
            i += 1
        }
        fields.append(currentField)
        return fields
    }
}
