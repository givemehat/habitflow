import Foundation
import AppIntents
import SwiftData
import WidgetKit

public struct ToggleHabitIntent: AppIntent, Sendable {
    public static var title: LocalizedStringResource = "Toggle Habit Completion"
    
    @Parameter(title: "Habit ID")
    public var habitId: UUID
    
    public init() {}
    
    public init(habitId: UUID) {
        self.habitId = habitId
    }
    
    @MainActor
    public func perform() async throws -> some IntentResult {
        do {
            // Instantiate SwiftData container with same schema
            let schema = Schema([Habit.self, HabitLog.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: config)
            let context = container.mainContext
            
            // Fetch the target habit
            let id = habitId
            var descriptor = FetchDescriptor<Habit>()
            descriptor.predicate = #Predicate<Habit> { $0.id == id }
            
            let habits = try context.fetch(descriptor)
            if let habit = habits.first {
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                
                if let existingLog = habit.logs.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
                    // Toggle off: Delete log
                    habit.logs.removeAll(where: { $0.id == existingLog.id })
                    context.delete(existingLog)
                } else {
                    // Toggle on: Create log
                    let newLog = HabitLog(id: UUID(), date: Date(), notes: "Completed from widget", habit: habit)
                    habit.logs.append(newLog)
                    context.insert(newLog)
                }
                
                try context.save()
                
                // Refresh all widget timelines
                WidgetCenter.shared.reloadAllTimelines()
            }
        } catch {
            print("Widget AppIntent failed: \(error.localizedDescription)")
        }
        
        return .result()
    }
}
