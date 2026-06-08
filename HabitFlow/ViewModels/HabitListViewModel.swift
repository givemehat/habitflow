import Foundation
import SwiftUI
import Observation

public enum CompletionFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case completedToday = "Completed Today"
    case incompleteToday = "Incomplete Today"
    
    public var id: String { self.rawValue }
}

public enum SortOption: String, CaseIterable, Identifiable, Sendable {
    case name = "Name"
    case streak = "Streak"
    case startDate = "Start Date"
    case category = "Category"
    
    public var id: String { self.rawValue }
}

@Observable
public final class HabitListViewModel: Sendable {
    public var searchQuery: String = ""
    public var selectedCategoryFilter: String? = nil // nil means All Categories
    public var completionFilter: CompletionFilter = .all
    public var sortBy: SortOption = .name
    
    public init() {}
    
    public func filteredAndSortedHabits(from habits: [Habit]) -> [Habit] {
        var result = habits
        
        // 1. Search Query
        if !searchQuery.isEmpty {
            result = result.filter { habit in
                habit.name.localizedCaseInsensitiveContains(searchQuery) ||
                habit.habitDescription.localizedCaseInsensitiveContains(searchQuery) ||
                habit.categoryName.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        
        // 2. Category Filter
        if let category = selectedCategoryFilter {
            result = result.filter { $0.categoryName == category }
        }
        
        // 3. Completion Filter (for today)
        let today = Date()
        switch completionFilter {
        case .all:
            break
        case .completedToday:
            result = result.filter { $0.isCompleted(on: today) }
        case .incompleteToday:
            result = result.filter { $0.isScheduled(on: today) && !$0.isCompleted(on: today) }
        }
        
        // 4. Sorting
        switch sortBy {
        case .name:
            result.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .streak:
            // Tie-break with name
            result.sort {
                let streak0 = $0.calculateCurrentStreak()
                let streak1 = $1.calculateCurrentStreak()
                if streak0 == streak1 {
                    return $0.name.localizedCompare($1.name) == .orderedAscending
                }
                return streak0 > streak1
            }
        case .startDate:
            result.sort {
                if $0.startDate == $1.startDate {
                    return $0.name.localizedCompare($1.name) == .orderedAscending
                }
                return $0.startDate < $1.startDate
            }
        case .category:
            result.sort {
                if $0.categoryName == $1.categoryName {
                    return $0.name.localizedCompare($1.name) == .orderedAscending
                }
                return $0.categoryName.localizedCompare($1.categoryName) == .orderedAscending
            }
        }
        
        return result
    }
}
