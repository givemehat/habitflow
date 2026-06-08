import Foundation
import SwiftData
import SwiftUI
import Observation
import WidgetKit

@Observable
public final class HabitDetailViewModel: Sendable {
    public init() {}
    
    // Toggle completion for a specific habit on a given date
    public func toggleCompletion(for habit: Habit, on date: Date, notes: String = "", in modelContext: ModelContext) {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        if let existingLog = habit.logs.first(where: { calendar.isDate($0.date, inSameDayAs: targetDate) }) {
            // Unmark complete (delete log)
            habit.logs.removeAll(where: { $0.id == existingLog.id })
            modelContext.delete(existingLog)
        } else {
            // Mark complete (create log)
            let newLog = HabitLog(id: UUID(), date: date, notes: notes, habit: habit)
            habit.logs.append(newLog)
            modelContext.insert(newLog)
        }
        
        saveContextAndRefreshWidgets(context: modelContext)
    }
    
    // Update notes for an existing log
    public func updateNotes(for log: HabitLog, notes: String, in modelContext: ModelContext) {
        log.notes = notes
        saveContextAndRefreshWidgets(context: modelContext)
    }
    
    // Delete log directly
    public func deleteLog(for habit: Habit, log: HabitLog, in modelContext: ModelContext) {
        habit.logs.removeAll(where: { $0.id == log.id })
        modelContext.delete(log)
        saveContextAndRefreshWidgets(context: modelContext)
    }
    
    private func saveContextAndRefreshWidgets(context: ModelContext) {
        do {
            try context.save()
            // Reload all interactive WidgetKit widgets immediately
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to save ModelContext: \(error)")
        }
    }
}
