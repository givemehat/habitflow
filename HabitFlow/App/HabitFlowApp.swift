import SwiftUI
import SwiftData

@main
struct HabitFlowApp: App {
    let container: ModelContainer
    
    init() {
        do {
            // Define SwiftData schema
            let schema = Schema([
                Habit.self,
                HabitLog.self,
                CustomCategory.self
            ])
            // Standard persistent store
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: config)
            
            // Trigger automatic backup check in the background
            Task { @MainActor in
                let context = container.mainContext
                let descriptor = FetchDescriptor<Habit>()
                if let habits = try? context.fetch(descriptor) {
                    BackupService.shared.performAutoBackupIfNeeded(habits: habits)
                }
            }
        } catch {
            fatalError("Could not initialize SwiftData ModelContainer: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainSidebarView()
                .modelContainer(container)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .commands {
            // File -> New Habit (⌘N)
            CommandGroup(replacing: .newItem) {
                Button("New Habit...") {
                    NotificationCenter.default.post(name: .createNewHabit, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
            
            // File -> Export (⌘E)
            CommandGroup(after: .importExport) {
                Button("Export Data...") {
                    NotificationCenter.default.post(name: .exportData, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command])
            }
            
            // Find -> Find/Search (⌘F)
            CommandGroup(replacing: .find) {
                Button("Search Habits...") {
                    NotificationCenter.default.post(name: .focusSearch, object: nil)
                }
                .keyboardShortcut("f", modifiers: [.command])
            }
            
            // Preferences (⌘,)
            CommandGroup(replacing: .appInfo) {
                Button("Settings...") {
                    NotificationCenter.default.post(name: .openPreferences, object: nil)
                }
                .keyboardShortcut(",", modifiers: [.command])
            }
        }
    }
}

// Notification names extension for system-wide shortcuts routing
extension Notification.Name {
    public static let createNewHabit = Notification.Name("com.habitflow.app.createNewHabit")
    public static let focusSearch = Notification.Name("com.habitflow.app.focusSearch")
    public static let exportData = Notification.Name("com.habitflow.app.exportData")
    public static let openPreferences = Notification.Name("com.habitflow.app.openPreferences")
}
