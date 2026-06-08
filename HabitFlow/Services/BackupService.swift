import Foundation
import SwiftData

// Struct for JSON serialization/deserialization of habits
public struct HabitBackupContainer: Codable {
    public struct HabitBackup: Codable {
        public let id: UUID
        public let name: String
        public let habitDescription: String
        public let categoryName: String
        public let icon: String
        public let colorHex: String
        public let goalTypeRaw: String
        public let customScheduleDaysRaw: String
        public let weeklyTargetCount: Int
        public let startDate: Date
        
        // Backup properties for custom reminder configurations
        public let reminderEnabled: Bool?
        public let reminderHour: Int?
        public let reminderMinute: Int?
        public let reminderDaysRaw: String?
        
        public let logs: [LogBackup]
    }
    
    public struct LogBackup: Codable {
        public let id: UUID
        public let date: Date
        public let notes: String
    }
    
    public let version: Int
    public let exportDate: Date
    public let habits: [HabitBackup]
}

public final class BackupService: Sendable {
    public static let shared = BackupService()
    
    private init() {}
    
    // Application Support Backup Directory
    private var backupDirectoryURL: URL? {
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let url = appSupportURL.appendingPathComponent("HabitFlow/backups", isDirectory: true)
        
        // Ensure directory exists
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        return url
    }
    
    // Perform auto backup if needed
    public func performAutoBackupIfNeeded(habits: [Habit]) {
        let manager = PreferencesManager.shared
        guard manager.preferences.autoBackupEnabled else { return }
        
        let now = Date()
        if let lastBackup = manager.preferences.lastBackupDate {
            let calendar = Calendar.current
            let diff = calendar.dateComponents([.day], from: lastBackup, to: now).day ?? 0
            if diff < 7 {
                return // Not time yet
            }
        }
        
        // Run backup
        let success = createBackup(habits: habits, filename: "autobackup_\(Int(now.timeIntervalSince1970)).json")
        if success {
            manager.preferences.lastBackupDate = now
            manager.savePreferences()
        }
    }
    
    // Generate backup JSON data
    public func generateBackupData(habits: [Habit]) -> Data? {
        let backups = habits.map { habit in
            let logBackups = habit.logs.map { log in
                HabitBackupContainer.LogBackup(id: log.id, date: log.date, notes: log.notes)
            }
            return HabitBackupContainer.HabitBackup(
                id: habit.id,
                name: habit.name,
                habitDescription: habit.habitDescription,
                categoryName: habit.categoryName,
                icon: habit.icon,
                colorHex: habit.colorHex,
                goalTypeRaw: habit.goalTypeRaw,
                customScheduleDaysRaw: habit.customScheduleDaysRaw,
                weeklyTargetCount: habit.weeklyTargetCount,
                startDate: habit.startDate,
                reminderEnabled: habit.reminderEnabled,
                reminderHour: habit.reminderHour,
                reminderMinute: habit.reminderMinute,
                reminderDaysRaw: habit.reminderDaysRaw,
                logs: logBackups
            )
        }
        
        let container = HabitBackupContainer(
            version: 1,
            exportDate: Date(),
            habits: backups
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(container)
    }
    
    // Create a local backup file
    public func createBackup(habits: [Habit], filename: String) -> Bool {
        guard let data = generateBackupData(habits: habits),
              let backupDir = backupDirectoryURL else {
            return false
        }
        
        let fileURL = backupDir.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL)
            return true
        } catch {
            print("Failed to write backup file: \(error)")
            return false
        }
    }
    
    // List all available backups
    public func listLocalBackups() -> [URL] {
        guard let backupDir = backupDirectoryURL else { return [] }
        let fileManager = FileManager.default
        let urls = try? fileManager.contentsOfDirectory(at: backupDir, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
        return urls?.sorted(by: { url1, url2 in
            let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            return date1 > date2
        }) ?? []
    }
    
    // Restore and merge habits from container data into ModelContext
    public func restore(from data: Data, into modelContext: ModelContext, mergeMode: String = "Merge") -> Bool {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let container = try? decoder.decode(HabitBackupContainer.self, from: data) else {
            return false
        }
        
        // Fetch existing habits to detect duplicates
        let descriptor = FetchDescriptor<Habit>()
        let existingHabits = (try? modelContext.fetch(descriptor)) ?? []
        
        for backup in container.habits {
            // Check duplicate by ID or Name
            let duplicate = existingHabits.first { $0.id == backup.id || $0.name.lowercased() == backup.name.lowercased() }
            
            if let existing = duplicate {
                if mergeMode == "Overwrite" {
                    // Update fields
                    existing.name = backup.name
                    existing.habitDescription = backup.habitDescription
                    existing.categoryName = backup.categoryName
                    existing.icon = backup.icon
                    existing.colorHex = backup.colorHex
                    existing.goalTypeRaw = backup.goalTypeRaw
                    existing.customScheduleDaysRaw = backup.customScheduleDaysRaw
                    existing.weeklyTargetCount = backup.weeklyTargetCount
                    existing.startDate = backup.startDate
                    
                    existing.reminderEnabled = backup.reminderEnabled ?? false
                    existing.reminderHour = backup.reminderHour ?? 9
                    existing.reminderMinute = backup.reminderMinute ?? 0
                    existing.reminderDaysRaw = backup.reminderDaysRaw ?? ""
                    
                    // Merge logs: add missing logs
                    let calendar = Calendar.current
                    for logBackup in backup.logs {
                        let alreadyLogged = existing.logs.contains { calendar.isDate($0.date, inSameDayAs: logBackup.date) }
                        if !alreadyLogged {
                            let newLog = HabitLog(id: logBackup.id, date: logBackup.date, notes: logBackup.notes, habit: existing)
                            existing.logs.append(newLog)
                            modelContext.insert(newLog)
                        }
                    }
                } else {
                    // Merge mode (default): only add missing history logs
                    let calendar = Calendar.current
                    for logBackup in backup.logs {
                        let alreadyLogged = existing.logs.contains { calendar.isDate($0.date, inSameDayAs: logBackup.date) }
                        if !alreadyLogged {
                            let newLog = HabitLog(id: logBackup.id, date: logBackup.date, notes: logBackup.notes, habit: existing)
                            existing.logs.append(newLog)
                            modelContext.insert(newLog)
                        }
                    }
                }
            } else {
                // Create brand new habit
                let newHabit = Habit(
                    id: backup.id,
                    name: backup.name,
                    habitDescription: backup.habitDescription,
                    categoryName: backup.categoryName,
                    icon: backup.icon,
                    colorHex: backup.colorHex,
                    weeklyTargetCount: backup.weeklyTargetCount,
                    startDate: backup.startDate,
                    reminderEnabled: backup.reminderEnabled ?? false,
                    reminderHour: backup.reminderHour ?? 9,
                    reminderMinute: backup.reminderMinute ?? 0,
                    reminderDays: []
                )
                newHabit.goalTypeRaw = backup.goalTypeRaw
                newHabit.customScheduleDaysRaw = backup.customScheduleDaysRaw
                newHabit.reminderDaysRaw = backup.reminderDaysRaw ?? ""
                modelContext.insert(newHabit)
                
                for logBackup in backup.logs {
                    let newLog = HabitLog(id: logBackup.id, date: logBackup.date, notes: logBackup.notes, habit: newHabit)
                    newHabit.logs.append(newLog)
                    modelContext.insert(newLog)
                }
            }
        }
        
        try? modelContext.save()
        return true
    }
}
