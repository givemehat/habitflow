import XCTest
import SwiftData
@testable import HabitFlow

final class HabitModelTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    
    @MainActor
    override func setUp() {
        super.setUp()
        do {
            let schema = Schema([Habit.self, HabitLog.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try ModelContainer(for: schema, configurations: config)
            context = container.mainContext
        } catch {
            XCTFail("Failed to initialize in-memory ModelContainer: \(error.localizedDescription)")
        }
    }
    
    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }
    
    func testHabitCreation() {
        let habit = Habit(
            name: "Read Swift Guide",
            habitDescription: "Read Apple documentation",
            categoryName: "Reading",
            icon: "book.fill",
            colorHex: "#FF9F0A",
            goalType: .daily
        )
        
        XCTAssertEqual(habit.name, "Read Swift Guide")
        XCTAssertEqual(habit.habitDescription, "Read Apple documentation")
        XCTAssertEqual(habit.categoryName, "Reading")
        XCTAssertEqual(habit.icon, "book.fill")
        XCTAssertEqual(habit.colorHex, "#FF9F0A")
        XCTAssertEqual(habit.goalType, .daily)
    }
    
    func testDailyGoalScheduling() {
        let habit = Habit(name: "Workout", categoryName: "Fitness", goalType: .daily)
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        XCTAssertTrue(habit.isScheduled(on: today))
        XCTAssertTrue(habit.isScheduled(on: tomorrow))
    }
    
    func testAlternateDaysScheduling() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let habit = Habit(name: "Gym", categoryName: "Fitness", goalType: .alternateDays, startDate: today)
        
        XCTAssertTrue(habit.isScheduled(on: today), "Day 0 should be scheduled")
        
        let day1 = calendar.date(byAdding: .day, value: 1, to: today)!
        XCTAssertFalse(habit.isScheduled(on: day1), "Day 1 should not be scheduled")
        
        let day2 = calendar.date(byAdding: .day, value: 2, to: today)!
        XCTAssertTrue(habit.isScheduled(on: day2), "Day 2 should be scheduled")
    }
    
    func testCustomScheduleDays() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Custom schedule on Monday (2), Wednesday (4), and Friday (6)
        let habit = Habit(
            name: "Coding Practice",
            categoryName: "Coding",
            goalType: .customSchedule,
            customScheduleDays: [2, 4, 6],
            startDate: today
        )
        
        // Find a Monday, Wednesday, and Tuesday
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 1 // Monday June 1, 2026
        
        let monday = calendar.date(from: components)!
        let tuesday = calendar.date(byAdding: .day, value: 1, to: monday)!
        let wednesday = calendar.date(byAdding: .day, value: 2, to: monday)!
        
        XCTAssertTrue(habit.isScheduled(on: monday), "Should be scheduled on Monday")
        XCTAssertFalse(habit.isScheduled(on: tuesday), "Should not be scheduled on Tuesday")
        XCTAssertTrue(habit.isScheduled(on: wednesday), "Should be scheduled on Wednesday")
    }
    
    @MainActor
    func testCompletionLogging() {
        let habit = Habit(name: "Journal", categoryName: "Personal Growth")
        context.insert(habit)
        
        let today = Date()
        XCTAssertFalse(habit.isCompleted(on: today))
        
        let log = HabitLog(date: today, notes: "Feeling great", habit: habit)
        habit.logs.append(log)
        context.insert(log)
        
        XCTAssertTrue(habit.isCompleted(on: today))
        XCTAssertEqual(habit.logs.count, 1)
        XCTAssertEqual(habit.logs.first?.notes, "Feeling great")
    }
}
