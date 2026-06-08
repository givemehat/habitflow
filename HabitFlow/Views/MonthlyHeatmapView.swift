import SwiftUI
import SwiftData

public struct MonthlyHeatmapView: View {
    public let habit: Habit
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewMode: HeatmapViewMode = .year
    @State private var selectedYearOffset: Int = 0 // 0 = current year/last 12 months, -1 = prior year
    
    public enum HeatmapViewMode: String, CaseIterable, Identifiable {
        case month = "Month View"
        case year = "Year View"
        
        public var id: String { self.rawValue }
    }
    
    public init(habit: Habit) {
        self.habit = habit
    }
    
    // Generate the cells based on selected view mode
    private var heatmapCells: [ContributionCell] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var startDate: Date
        var endDate: Date
        
        switch viewMode {
        case .month:
            // Get current month range
            let components = calendar.dateComponents([.year, .month], from: today)
            guard let monthStart = calendar.date(from: components) else { return [] }
            guard let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else { return [] }
            startDate = monthStart
            endDate = monthEnd
            
        case .year:
            // Get the last 365 days
            guard let yearAgo = calendar.date(byAdding: .day, value: -364, to: today) else { return [] }
            startDate = yearAgo
            endDate = today
        }
        
        // Populate dates day-by-day
        var cells: [ContributionCell] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let isScheduled = habit.isScheduled(on: currentDate)
            let isCompleted = habit.isCompleted(on: currentDate)
            
            cells.append(
                ContributionCell(
                    date: currentDate,
                    isScheduled: isScheduled,
                    isCompleted: isCompleted,
                    completionFraction: 0.0,
                    count: isCompleted ? 1 : 0
                )
            )
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return cells
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Consistency Map")
                    .font(.headline)
                
                Spacer()
                
                Picker("View Mode", selection: $viewMode) {
                    ForEach(HeatmapViewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            let cells = heatmapCells
            
            if cells.isEmpty {
                ContentUnavailableView(
                    "No Data Available",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("No schedule could be calculated for this period.")
                )
            } else {
                let prefs = PreferencesManager.shared.preferences
                
                VStack(alignment: .leading, spacing: 6) {
                    ContributionGridView(
                        cells: cells,
                        baseColor: Color(hex: habit.colorHex),
                        gridStyle: prefs.gridStyle,
                        cornerRadius: CGFloat(prefs.cornerRadius),
                        cellSize: viewMode == .month ? 18 : 12,
                        spacing: prefs.layoutDensity.padding,
                        onCellSelected: { clickedDate in
                            // Toggle completion with a brief default note
                            let detailVM = HabitDetailViewModel()
                            detailVM.toggleCompletion(for: habit, on: clickedDate, notes: "Logged via heatmap", in: modelContext)
                        }
                    )
                    
                    // Legend
                    HStack(spacing: 4) {
                        Text("Less").font(.caption2).foregroundColor(.secondary)
                        
                        let baseColor = Color(hex: habit.colorHex)
                        // Incomplete cell representation
                        RoundedRectangle(cornerRadius: prefs.gridStyle.cornerRadius(cellSize: 8))
                            .fill(Color.primary.opacity(0.08))
                            .frame(width: 8, height: 8)
                        
                        // Completed cell representation
                        RoundedRectangle(cornerRadius: prefs.gridStyle.cornerRadius(cellSize: 8))
                            .fill(baseColor)
                            .frame(width: 8, height: 8)
                        
                        Text("More").font(.caption2).foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Click any scheduled square to toggle completion.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
                .padding(12)
                .background(Color(NSColor.windowBackgroundColor).opacity(0.4))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
            }
        }
    }
}
