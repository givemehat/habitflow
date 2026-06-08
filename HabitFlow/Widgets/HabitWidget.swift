import WidgetKit
import SwiftUI
import SwiftData

public struct HabitWidgetEntry: TimelineEntry {
    public let date: Date
    public let habits: [Habit]
    public let widgetTheme: WidgetThemeType
}

public struct HabitWidgetProvider: TimelineProvider {
    public typealias Entry = HabitWidgetEntry
    
    public init() {}
    
    // Default placeholder
    public func placeholder(in context: Context) -> HabitWidgetEntry {
        HabitWidgetEntry(date: Date(), habits: [], widgetTheme: .minimal)
    }
    
    // Quick preview
    public func getSnapshot(in context: Context, completion: @escaping (HabitWidgetEntry) -> Void) {
        let entry = HabitWidgetEntry(date: Date(), habits: sampleHabits(), widgetTheme: .minimal)
        completion(entry)
    }
    
    // Core timeline generator
    public func getTimeline(in context: Context, completion: @escaping (Timeline<HabitWidgetEntry>) -> Void) {
        let habits = fetchHabitsFromSwiftData()
        
        // Retrieve saved widget theme preference
        PreferencesManager.shared.loadPreferences()
        let theme = PreferencesManager.shared.preferences.widgetTheme
        
        let entry = HabitWidgetEntry(date: Date(), habits: habits, widgetTheme: theme)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    // SwiftData loading
    @MainActor
    private func fetchHabitsFromSwiftData() -> [Habit] {
        do {
            let schema = Schema([Habit.self, HabitLog.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: config)
            let context = container.mainContext
            let descriptor = FetchDescriptor<Habit>()
            return try context.fetch(descriptor)
        } catch {
            print("Widget failed to load SwiftData container: \(error.localizedDescription)")
            return []
        }
    }
    
    private func sampleHabits() -> [Habit] {
        let h1 = Habit(name: "Morning Meditate", categoryName: "Meditation", icon: "brain.headprofile.peace", colorHex: "#BF5AF2")
        let h2 = Habit(name: "Read 20 Pages", categoryName: "Reading", icon: "book.fill", colorHex: "#FF9F0A")
        return [h1, h2]
    }
}

// Main View for Widgets
struct HabitWidgetEntryView: View {
    var entry: HabitWidgetProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            widgetBackground(theme: entry.widgetTheme)
            
            VStack(alignment: .leading, spacing: 8) {
                switch family {
                case .systemSmall:
                    smallWidgetView
                case .systemMedium:
                    mediumWidgetView
                default: // systemLarge
                    largeWidgetView
                }
            }
            .padding(12)
        }
    }
    
    // Small Widget: Focuses on a single high-priority/first habit
    @ViewBuilder
    private var smallWidgetView: some View {
        if let firstHabit = entry.habits.first {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: firstHabit.colorHex).opacity(0.15))
                            .frame(width: 28, height: 28)
                        Image(systemName: firstHabit.icon)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: firstHabit.colorHex))
                    }
                    
                    Spacer()
                    
                    // Interactive checkbox button
                    Button(intent: ToggleHabitIntent(habitId: firstHabit.id)) {
                        Image(systemName: firstHabit.isCompleted(on: Date()) ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(firstHabit.isCompleted(on: Date()) ? Color(hex: firstHabit.colorHex) : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Text(firstHabit.name)
                    .font(.subheadline)
                    .bold()
                    .lineLimit(1)
                    .padding(.top, 4)
                
                let streak = firstHabit.calculateCurrentStreak()
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(streak) day streak")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .opacity(streak > 0 ? 1 : 0)
                
                Spacer()
            }
        } else {
            emptyStateView
        }
    }
    
    // Medium Widget: Lists top 3 habits with checklist buttons
    @ViewBuilder
    private var mediumWidgetView: some View {
        if entry.habits.isEmpty {
            emptyStateView
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("Today's Habits")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.secondary)
                
                ForEach(entry.habits.prefix(3)) { habit in
                    HStack {
                        Button(intent: ToggleHabitIntent(habitId: habit.id)) {
                            Image(systemName: habit.isCompleted(on: Date()) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(habit.isCompleted(on: Date()) ? Color(hex: habit.colorHex) : .secondary)
                        }
                        .buttonStyle(.plain)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(habit.name)
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(1)
                            
                            let streak = habit.calculateCurrentStreak()
                            if streak > 0 {
                                Text("\(streak)d streak")
                                    .font(.system(size: 8))
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: habit.icon)
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: habit.colorHex))
                    }
                    .padding(.vertical, 2)
                    
                    if habit.id != entry.habits.prefix(3).last?.id {
                        Divider().opacity(0.3)
                    }
                }
            }
        }
    }
    
    // Large Widget: Comprehensive stats and habits overview
    @ViewBuilder
    private var largeWidgetView: some View {
        if entry.habits.isEmpty {
            emptyStateView
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Habit Tracker")
                        .font(.headline)
                    Spacer()
                    let completed = entry.habits.filter({ $0.isCompleted(on: Date()) }).count
                    Text("\(completed)/\(entry.habits.count) Done")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                
                Divider()
                
                ForEach(entry.habits.prefix(5)) { habit in
                    HStack {
                        Button(intent: ToggleHabitIntent(habitId: habit.id)) {
                            Image(systemName: habit.isCompleted(on: Date()) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(habit.isCompleted(on: Date()) ? Color(hex: habit.colorHex) : .secondary)
                        }
                        .buttonStyle(.plain)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(habit.name)
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                            
                            Text(habit.categoryName)
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        let streak = habit.calculateCurrentStreak()
                        if streak > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                Text("\(streak)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 1)
                }
                
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.title)
                .foregroundColor(.blue)
            Text("No Habits")
                .font(.subheadline)
                .bold()
            Text("Create in app")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Widget Theme Background Builder
    @ViewBuilder
    private func widgetBackground(theme: WidgetThemeType) -> some View {
        switch theme {
        case .minimal:
            Color(NSColor.windowBackgroundColor)
        case .glass:
            Color.clear
                .background(.ultraThinMaterial)
        case .monochrome:
            Color.black
        case .github:
            Color(hex: "#0d1117") // GitHub Dark Background
        case .appleNotes:
            Color(hex: "#fcf8f2") // Warm notes yellow/white paper
                .overlay(
                    // Notes margins line
                    HStack {
                        Rectangle()
                            .fill(Color.red.opacity(0.4))
                            .frame(width: 1.5)
                            .padding(.leading, 24)
                        Spacer()
                    }
                )
        }
    }
}
