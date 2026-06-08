import XCTest
import SwiftData
@testable import HabitFlow

final class StatisticsTests: XCTestCase {
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
    
    @MainActor
    func testStreakCalculations() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        
        // Start date: 4 days ago
        let startDate = calendar.date(byAdding: .day, value: -4, to: today)!
        let habit = Habit(name: "Hydrate", categoryName: "Health", goalType: .daily, startDate: startDate)
        context.insert(habit)
        
        // Log completions for threeDaysAgo, twoDaysAgo, yesterday
        let log1 = HabitLog(date: threeDaysAgo, notes: "", habit: habit)
        let log2 = HabitLog(date: twoDaysAgo, notes: "", habit: habit)
        let log3 = HabitLog(date: yesterday, notes: "", habit: habit)
        
        habit.logs.append(contentsOf: [log1, log2, log3])
        context.insert(log1)
        context.insert(log2)
        context.insert(log3)
        
        // Today is not completed yet. Since yesterday was completed, the current streak should still be 3!
        XCTAssertEqual(habit.calculateCurrentStreak(), 3)
        
        // Log completion for today. Now streak should be 4!
        let logToday = HabitLog(date: today, notes: "", habit: habit)
        habit.logs.append(logToday)
        context.insert(logToday)
        XCTAssertEqual(habit.calculateCurrentStreak(), 4)
        
        // Test longest streak
        XCTAssertEqual(habit.calculateLongestStreak(), 4)
    }
    
    @MainActor
    func testBrokenStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        
        let habit = Habit(name: "Floss", categoryName: "Health", goalType: .daily, startDate: threeDaysAgo)
        context.insert(habit)
        
        // Completed threeDaysAgo, missed twoDaysAgo, completed yesterday, today incomplete
        let log1 = HabitLog(date: threeDaysAgo, notes: "", habit: habit)
        let log3 = HabitLog(date: yesterday, notes: "", habit: habit)
        
        habit.logs.append(contentsOf: [log1, log3])
        context.insert(log1)
        context.insert(log3)
        
        // Since yesterday was completed but twoDaysAgo was missed, current streak is 1 (yesterday only)
        XCTAssertEqual(habit.calculateCurrentStreak(), 1)
        
        // Longest streak was 1
        XCTAssertEqual(habit.calculateLongestStreak(), 1)
    }
    
    @MainActor
    func testDashboardViewModelAggregates() {
        let vm = DashboardViewModel()
        
        let today = Date()
        let h1 = Habit(name: "A", categoryName: "Study", goalType: .daily, startDate: today)
        let h2 = Habit(name: "B", categoryName: "Reading", goalType: .daily, startDate: today)
        let h3 = Habit(name: "C", categoryName: "Study", goalType: .daily, startDate: today)
        
        let habits = [h1, h2, h3]
        
        // Total habits count
        XCTAssertEqual(vm.totalHabits(from: habits), 3)
        
        // Today completion rate before checkoff
        XCTAssertEqual(vm.todayCompletionRate(from: habits), 0.0)
        
        // Mark h1 complete
        let log = HabitLog(date: today, notes: "", habit: h1)
        h1.logs.append(log)
        
        // Now completion rate should be 1/3 (33%)
        XCTAssertEqual(vm.todayCompletionRate(from: habits), 1.0/3.0)
        
        // Check category distribution
        let dist = vm.categoryDistribution(from: habits)
        XCTAssertEqual(dist.count, 2) // Study and Reading
        XCTAssertEqual(dist.first(where: { $0.categoryName == "Study" })?.habitCount, 2)
        XCTAssertEqual(dist.first(where: { $0.categoryName == "Reading" })?.habitCount, 1)
    }
}
