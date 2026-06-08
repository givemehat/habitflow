//
//  habitflow-cli.swift
//  HabitFlow
//
//  Created by Rajnish Singh on 08/06/2026.
//  Copyright © 2026 Rajnish Singh. All rights reserved.
//

import Foundation

// MARK: - Core Models

struct HabitLog: Codable {
    var id: UUID
    var date: Date
    var notes: String
}

enum GoalType: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case alternateDays = "Alternate Days"
    case customSchedule = "Custom Schedule"
}

struct CLIHabit: Codable {
    var id: UUID
    var name: String
    var habitDescription: String
    var categoryName: String
    var icon: String
    var colorHex: String
    var goalType: GoalType
    var customScheduleDays: [Int] // 1 = Sunday ... 7 = Saturday
    var weeklyTargetCount: Int
    var startDate: Date
    var logs: [HabitLog]
    
    var reminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var reminderDays: [Int]
    
    // Checks if the habit has a task required on a specific date
    func isScheduled(on date: Date) -> Bool {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        if targetDate < calendar.startOfDay(for: startDate) {
            return false
        }
        
        switch goalType {
        case .daily:
            return true
        case .weekly:
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
    
    // Checks if completed on a specific date
    func isCompleted(on date: Date) -> Bool {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        return logs.contains { calendar.isDate($0.date, inSameDayAs: targetDay) }
    }
}

// MARK: - Statistics Manager

final class StatsManager {
    static func calculateCurrentStreak(for habit: CLIHabit) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let completedDates = habit.logs.map { calendar.startOfDay(for: $0.date) }.sorted(by: >)
        
        if completedDates.isEmpty { return 0 }
        
        var currentDate = today
        var streak = 0
        var isFirstCheck = true
        
        if !habit.isScheduled(on: today) && !completedDates.contains(today) {
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
                currentDate = yesterday
            }
        }
        
        while true {
            if currentDate < calendar.startOfDay(for: habit.startDate) { break }
            
            if habit.isScheduled(on: currentDate) {
                if completedDates.contains(currentDate) {
                    streak += 1
                } else {
                    if isFirstCheck && currentDate == today {
                        // Skip checking today if it's not checked off yet
                    } else {
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
    
    static func calculateLongestStreak(for habit: CLIHabit) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard habit.startDate <= today else { return 0 }
        
        var tempStreak = 0
        var maxStreak = 0
        var currentDate = calendar.startOfDay(for: habit.startDate)
        let completedDates = Set(habit.logs.map { calendar.startOfDay(for: $0.date) })
        
        while currentDate <= today {
            if habit.isScheduled(on: currentDate) {
                if completedDates.contains(currentDate) {
                    tempStreak += 1
                    if tempStreak > maxStreak {
                        maxStreak = tempStreak
                    }
                } else {
                    if calendar.isDateInToday(currentDate) {
                        // skip breaking today
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

// MARK: - CLI Application

final class HabitFlowCLI {
    private let fileURL = URL(fileURLWithPath: "habits.json")
    private var habits: [CLIHabit] = []
    
    init() {
        loadData()
    }
    
    // MARK: Data Management
    
    private func loadData() {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                habits = try decoder.decode([CLIHabit].self, from: data)
            } catch {
                print("\u{001B}[31mError loading data: \(error.localizedDescription)\u{001B}[0m")
            }
        }
    }
    
    private func saveData() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(habits)
            try data.write(to: fileURL)
        } catch {
            print("\u{001B}[31mError saving data: \(error.localizedDescription)\u{001B}[0m")
        }
    }
    
    // MARK: Run Loop
    
    func run() {
        clearScreen()
        printLogo()
        
        var shouldExit = false
        while !shouldExit {
            printMenu()
            guard let choice = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { continue }
            
            switch choice {
            case "1":
                showDashboard()
            case "2":
                toggleHabitMenu()
            case "3":
                createHabitMenu()
            case "4":
                deleteHabitMenu()
            case "5":
                exportCSV()
            case "6":
                shouldExit = true
                print("\n\u{001B}[32mThank you for using HabitFlow. Keep up the consistency!\u{001B}[0m\n")
            default:
                print("\u{001B}[31mInvalid option. Please enter 1-6.\u{001B}[0m")
            }
        }
    }
    
    // MARK: CLI Views
    
    private func clearScreen() {
        print("\u{001B}[2J\u{001B}[H", terminator: "")
    }
    
    private func printLogo() {
        print("""
        \u{001B}[36;1m
        ██╗  ██╗ █████╗ ██████╗ ██╗████████╗███████╗██╗      ██████╗ ██╗    ██╗
        ██║  ██║██╔══██╗██╔══██╗██║╚══██╔══╝██╔════╝██║     ██╔═══██╗██║    ██║
        ███████║███████║██████╔╝██║   ██║   █████╗  ██║     ██║   ██║██║ █╗ ██║
        ██╔══██║██╔══██║██╔══██╗██║   ██║   ██╔══╝  ██║     ██║   ██║██║███╗██║
        ██║  ██║██║  ██║██████╔╝██║   ██║   ██║     ███████╗╚██████╔╝╚███╔███╔╝
        ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝   ╚═╝   ╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝ 
        \u{001B}[0m
        Developed by Rajnish Singh | Version 1.0.0 (CLI Edition)
        """)
    }
    
    private func printMenu() {
        print("""
        
        \u{001B}[33;1m--- MAIN MENU ---\u{001B}[0m
        1. View Dashboard & Heatmap
        2. Check-in / Toggle Habit
        3. Create New Habit
        4. Delete a Habit
        5. Export to CSV
        6. Exit
        
        Select an option (1-6): 
        """, terminator: "")
    }
    
    private func showDashboard() {
        clearScreen()
        printLogo()
        
        print("\n\u{001B}[35;1m=== TODAY'S HABITS DASHBOARD ===\u{001B}[0m")
        if habits.isEmpty {
            print("No habits created yet. Select option 3 to add one!")
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var scheduledToday = 0
        var completedToday = 0
        
        for habit in habits {
            let isSched = habit.isScheduled(on: today)
            let isComp = habit.isCompleted(on: today)
            
            if isSched {
                scheduledToday += 1
                if isComp { completedToday += 1 }
            }
            
            let currentStr = StatsManager.calculateCurrentStreak(for: habit)
            let longestStr = StatsManager.calculateLongestStreak(for: habit)
            
            let statusChar = isComp ? "\u{001B}[32m[✓]\u{001B}[0m" : "\u{001B}[31m[ ]\u{001B}[0m"
            print("\(statusChar) \(habit.name) (\(habit.categoryName)) | Streak: \(currentStr)d (Best: \(longestStr)d)")
        }
        
        if scheduledToday > 0 {
            let rate = Int((Double(completedToday) / Double(scheduledToday)) * 100)
            print("\nToday's Progress: \(completedToday)/\(scheduledToday) completed (\(rate)%)")
        }
        
        printHeatmap()
    }
    
    private func printHeatmap() {
        print("\n\u{001B}[35;1m=== 12-WEEK CONTRIBUTION HEATMAP ===\u{001B}[0m")
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Find Monday of 12 weeks ago
        guard let twelveWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -11, to: today) else { return }
        let weekday = calendar.component(.weekday, from: twelveWeeksAgo)
        let offsetToSunday = weekday - 1
        guard let startDate = calendar.date(byAdding: .day, value: -offsetToSunday, to: twelveWeeksAgo) else { return }
        
        // Build the grid of dates (7 rows for Sunday-Saturday, columns for weeks)
        var grid: [[Date]] = Array(repeating: [], count: 7)
        var testDate = startDate
        
        while testDate <= today {
            let wday = calendar.component(.weekday, from: testDate) - 1 // 0 = Sunday
            grid[wday].append(testDate)
            
            guard let next = calendar.date(byAdding: .day, value: 1, to: testDate) else { break }
            testDate = next
        }
        
        let weekdayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        for r in 0..<7 {
            var rowStr = "\(weekdayNames[r]) "
            for date in grid[r] {
                // Determine completion intensity across all active habits
                var scheduledCount = 0
                var completedCount = 0
                
                for habit in habits {
                    if habit.isScheduled(on: date) {
                        scheduledCount += 1
                        if habit.isCompleted(on: date) {
                            completedCount += 1
                        }
                    }
                }
                
                if scheduledCount == 0 {
                    rowStr += "\u{001B}[30;1m. \u{001B}[0m" // Not scheduled / empty slot
                } else if completedCount == 0 {
                    rowStr += "\u{001B}[90m□ \u{001B}[0m" // Scheduled but 0 completed
                } else {
                    let fraction = Double(completedCount) / Double(scheduledCount)
                    if fraction <= 0.34 {
                        rowStr += "\u{001B}[32m■ \u{001B}[0m" // Light green
                    } else if fraction <= 0.67 {
                        rowStr += "\u{001B}[32;1m■ \u{001B}[0m" // Medium green
                    } else {
                        rowStr += "\u{001B}[30;42m■\u{001B}[0m " // Highlighted dark green
                    }
                }
            }
            print(rowStr)
        }
        print("\nLegend: . Not Scheduled | □ 0% Complete | ■ 1-33% | \u{001B}[32;1m■\u{001B}[0m 34-66% | \u{001B}[30;42m■\u{001B}[0m 67-100%")
    }
    
    private func toggleHabitMenu() {
        print("\n\u{001B}[33;1m=== SELECT HABIT TO CHECK IN / OUT ===\u{001B}[0m")
        if habits.isEmpty {
            print("No habits found.")
            return
        }
        
        for (index, habit) in habits.enumerated() {
            let isComp = habit.isCompleted(on: Date())
            let status = isComp ? "\u{001B}[32m[Completed]\u{001B}[0m" : "\u{001B}[31m[Incomplete]\u{001B}[0m"
            print("\(index + 1). \(habit.name) \(status)")
        }
        
        print("\nEnter habit number to toggle (or Enter to cancel): ", terminator: "")
        guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
              let num = Int(input),
              num > 0 && num <= habits.count else { return }
        
        var habit = habits[num - 1]
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let index = habit.logs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            habit.logs.remove(at: index)
            print("\u{001B}[33mUnmarked \(habit.name) as completed for today.\u{001B}[0m")
        } else {
            print("Enter notes for this check-in (Optional): ", terminator: "")
            let notes = readLine() ?? ""
            let log = HabitLog(id: UUID(), date: Date(), notes: notes)
            habit.logs.append(log)
            print("\u{001B}[32mMarked \(habit.name) as completed for today!\u{001B}[0m")
        }
        
        habits[num - 1] = habit
        saveData()
    }
    
    private func createHabitMenu() {
        print("\n\u{001B}[33;1m=== CREATE NEW HABIT ===\u{001B}[0m")
        
        print("Enter Habit Name: ", terminator: "")
        guard let name = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            print("\u{001B}[31mHabit name cannot be empty.\u{001B}[0m")
            return
        }
        
        print("Enter Description (Optional): ", terminator: "")
        let desc = readLine() ?? ""
        
        print("Enter Category (e.g. Health, Coding, Study): ", terminator: "")
        let category = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "General"
        
        print("""
        Select Goal Type:
        1. Daily (Every day)
        2. Alternate Days (Every second day)
        3. Custom Days (Select weekdays)
        Select option (1-3): 
        """, terminator: "")
        let typeChoice = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var goalType: GoalType = .daily
        var customDays: [Int] = []
        
        if typeChoice == "2" {
            goalType = .alternateDays
        } else if typeChoice == "3" {
            goalType = .customSchedule
            print("Select weekdays (comma-separated, e.g. 2,4,6 for Mon,Wed,Fri - where 1=Sun, 2=Mon...7=Sat): ", terminator: "")
            if let daysInput = readLine() {
                customDays = daysInput.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            }
            if customDays.isEmpty { customDays = [2, 4, 6] }
        }
        
        let newHabit = CLIHabit(
            id: UUID(),
            name: name,
            habitDescription: desc,
            categoryName: category,
            icon: "checkmark.circle",
            colorHex: "#0A84FF",
            goalType: goalType,
            customScheduleDays: customDays,
            weeklyTargetCount: 1,
            startDate: Date(),
            logs: [],
            reminderEnabled: false,
            reminderHour: 9,
            reminderMinute: 0,
            reminderDays: []
        )
        
        habits.append(newHabit)
        saveData()
        print("\u{001B}[32mHabit \"\(name)\" created successfully!\u{001B}[0m")
    }
    
    private func deleteHabitMenu() {
        print("\n\u{001B}[31;1m=== DELETE A HABIT ===\u{001B}[0m")
        if habits.isEmpty {
            print("No habits found.")
            return
        }
        
        for (index, habit) in habits.enumerated() {
            print("\(index + 1). \(habit.name)")
        }
        
        print("\nEnter habit number to delete (or Enter to cancel): ", terminator: "")
        guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
              let num = Int(input),
              num > 0 && num <= habits.count else { return }
        
        let deleted = habits.remove(at: num - 1)
        saveData()
        print("\u{001B}[32mDeleted habit \"\(deleted.name)\" successfully.\u{001B}[0m")
    }
    
    private func exportCSV() {
        print("\n\u{001B}[33;1m=== EXPORT TO CSV ===\u{001B}[0m")
        var csv = "Habit ID,Name,Description,Category,Goal Type,Start Date,Completions Count,Log Dates\n"
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        
        for habit in habits {
            let id = habit.id.uuidString
            let name = habit.name.replacingOccurrences(of: ",", with: " ")
            let desc = habit.habitDescription.replacingOccurrences(of: ",", with: " ")
            let category = habit.categoryName.replacingOccurrences(of: ",", with: " ")
            let goalType = habit.goalType.rawValue
            let startDate = dateFormatter.string(from: habit.startDate)
            let completionsCount = habit.logs.count
            let logDates = habit.logs.map { dateFormatter.string(from: $0.date) }.joined(separator: ";")
            
            csv += "\(id),\(name),\(desc),\(category),\(goalType),\(startDate),\(completionsCount),\"\(logDates)\"\n"
        }
        
        do {
            try csv.write(toFile: "HabitFlow_Export.csv", atomically: true, encoding: .utf8)
            print("\u{001B}[32mData exported successfully to \"HabitFlow_Export.csv\"!\u{001B}[0m")
        } catch {
            print("\u{001B}[31mFailed to write CSV: \(error.localizedDescription)\u{001B}[0m")
        }
    }
}

// MARK: - Main Execution

let cli = HabitFlowCLI()
cli.run()
