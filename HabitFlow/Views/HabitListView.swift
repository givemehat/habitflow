import SwiftUI
import SwiftData

struct HabitListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    
    @State private var viewModel = HabitListViewModel()
    @State private var selectedHabit: Habit?
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Filters & Search Bar
                VStack(spacing: 8) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search habits...", text: $viewModel.searchQuery)
                            .textFieldStyle(.plain)
                            .focused($isSearchFocused)
                        
                        if !viewModel.searchQuery.isEmpty {
                            Button(action: { viewModel.searchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .background(Color.primary.opacity(0.06))
                    .cornerRadius(6)
                    
                    // Filter Pickers
                    HStack {
                        Picker("Category", selection: $viewModel.selectedCategoryFilter) {
                            Text("All Categories").tag(nil as String?)
                            
                            // Combine built-in & custom categories
                            ForEach(BuiltInCategory.allCases) { cat in
                                Text(cat.rawValue).tag(cat.rawValue as String?)
                            }
                        }
                        .labelsHidden()
                        .controlSize(.small)
                        
                        Picker("Status", selection: $viewModel.completionFilter) {
                            ForEach(CompletionFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .labelsHidden()
                        .controlSize(.small)
                    }
                    
                    HStack {
                        Picker("Sort By", selection: $viewModel.sortBy) {
                            ForEach(SortOption.allCases) { option in
                                Text("Sort: \(option.rawValue)").tag(option)
                            }
                        }
                        .labelsHidden()
                        .controlSize(.small)
                        
                        Spacer()
                    }
                }
                .padding(12)
                .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                
                Divider()
                
                // Habit List
                let list = viewModel.filteredAndSortedHabits(from: habits)
                
                if list.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "square.dashed")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No matching habits")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List(selection: $selectedHabit) {
                        ForEach(list) { habit in
                            HabitRowView(habit: habit, isSelected: selectedHabit?.id == habit.id) {
                                // Toggle completion
                                let detailVM = HabitDetailViewModel()
                                detailVM.toggleCompletion(for: habit, on: Date(), in: modelContext)
                            }
                            .tag(habit)
                        }
                    }
                    .listStyle(.inset)
                }
            }
            .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 350)
        } detail: {
            if let selected = selectedHabit {
                HabitDetailView(habit: selected)
            } else {
                ContentUnavailableView(
                    "No Habit Selected",
                    systemImage: "checklist.checked",
                    description: Text("Select a habit from the list or press ⌘N to create a new one.")
                )
            }
        }
        // Listen to ⌘F Search Focus Notification
        .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in
            isSearchFocused = true
        }
        // Enable Spacebar shortcut to check off selected habit
        .background(
            Button(action: toggleSelectedCompletion) {
                EmptyView()
            }
            .keyboardShortcut(.space, modifiers: [])
            .opacity(0)
        )
    }
    
    private func toggleSelectedCompletion() {
        guard let selected = selectedHabit else { return }
        let detailVM = HabitDetailViewModel()
        detailVM.toggleCompletion(for: selected, on: Date(), in: modelContext)
    }
}

// Habit Row Component
struct HabitRowView: View {
    let habit: Habit
    let isSelected: Bool
    let onToggleComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox button
            Button(action: onToggleComplete) {
                Image(systemName: habit.isCompleted(on: Date()) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(habit.isCompleted(on: Date()) ? Color(hex: habit.colorHex) : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(habit.isCompleted(on: Date()) ? "Completed" : "Mark completed")
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(habit.name)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Streak Badge
                    let streak = habit.calculateCurrentStreak()
                    if streak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(streak)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(isSelected ? .white : .secondary)
                        }
                    }
                }
                
                HStack(spacing: 6) {
                    // Icon + Category
                    Image(systemName: habit.icon)
                        .font(.caption)
                        .foregroundColor(Color(hex: habit.colorHex))
                    
                    Text(habit.categoryName)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Schedule indicator
                    Text(habit.goalType.rawValue)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
