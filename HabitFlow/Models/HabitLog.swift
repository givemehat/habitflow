import Foundation
import SwiftData

@Model
public final class HabitLog {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var notes: String
    
    public var habit: Habit?
    
    public init(id: UUID = UUID(), date: Date = Date(), notes: String = "", habit: Habit? = nil) {
        self.id = id
        // Normalize the date to start of day or save full timestamp depending on need.
        // We preserve full timestamp for temporal completion analysis (e.g. "drops after 8 PM")
        self.date = date
        self.notes = notes
        self.habit = habit
    }
}
