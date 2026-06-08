import WidgetKit
import SwiftUI

@main
struct HabitWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabitWidget()
    }
}

public struct HabitWidget: Widget {
    private let kind: String = "HabitFlowWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitWidgetProvider()) { entry in
            HabitWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("HabitFlow")
        .description("Quickly check off habits and track active streaks directly from your Desktop.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
