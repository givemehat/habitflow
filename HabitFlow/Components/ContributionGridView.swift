import SwiftUI

public struct ContributionCell: Identifiable, Sendable {
    public let id = UUID()
    public let date: Date
    public let isScheduled: Bool
    public let isCompleted: Bool
    public let completionFraction: Double // 0.0 to 1.0 (for aggregate views)
    public let count: Int // raw completions
}

public struct ContributionGridView: View {
    public let cells: [ContributionCell]
    public let baseColor: Color
    public let gridStyle: GridStyle
    public let cornerRadius: CGFloat
    public let cellSize: CGFloat
    public let spacing: CGFloat
    public let onCellSelected: @Sendable (Date) -> Void
    
    @State private var hoveredCellID: UUID? = nil
    
    public init(
        cells: [ContributionCell],
        baseColor: Color = .green,
        gridStyle: GridStyle = .rounded,
        cornerRadius: CGFloat = 3.0,
        cellSize: CGFloat = 12.0,
        spacing: CGFloat = 3.0,
        onCellSelected: @escaping @Sendable (Date) -> Void
    ) {
        self.cells = cells
        self.baseColor = baseColor
        self.gridStyle = gridStyle
        self.cornerRadius = cornerRadius
        self.cellSize = cellSize
        self.spacing = spacing
        self.onCellSelected = onCellSelected
    }
    
    // Group cells into weeks (7 days each) for vertical or horizontal layout
    // We group them such that columns represent weeks, and rows represent weekdays (GitHub-style)
    private var columns: [[ContributionCell]] {
        guard !cells.isEmpty else { return [] }
        
        var cols: [[ContributionCell]] = []
        var currentWeek: [ContributionCell] = []
        
        let calendar = Calendar.current
        
        // Pad the start so the first weekday aligns correctly
        if let firstCell = cells.first {
            let weekday = calendar.component(.weekday, from: firstCell.date)
            let paddingCount = weekday - 1 // 1 = Sunday, so 0 padding
            if paddingCount > 0 {
                // Add dummy empty cells
                for _ in 0..<paddingCount {
                    // We use distantPast to indicate dummy
                    currentWeek.append(ContributionCell(date: Date.distantPast, isScheduled: false, isCompleted: false, completionFraction: 0, count: 0))
                }
            }
        }
        
        for cell in cells {
            currentWeek.append(cell)
            if currentWeek.count == 7 {
                cols.append(currentWeek)
                currentWeek = []
            }
        }
        
        // Pad the end
        if !currentWeek.isEmpty {
            while currentWeek.count < 7 {
                currentWeek.append(ContributionCell(date: Date.distantPast, isScheduled: false, isCompleted: false, completionFraction: 0, count: 0))
            }
            cols.append(currentWeek)
        }
        
        return cols
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            // Weekday labels on the left (Sun, Tue, Thu, Sat or Mon, Wed, Fri)
            VStack(alignment: .leading, spacing: spacing) {
                Spacer().frame(height: cellSize + spacing) // alignment
                Text("Mon").font(.system(size: 8, weight: .medium)).foregroundColor(.secondary).frame(height: cellSize)
                Spacer().frame(height: cellSize)
                Text("Wed").font(.system(size: 8, weight: .medium)).foregroundColor(.secondary).frame(height: cellSize)
                Spacer().frame(height: cellSize)
                Text("Fri").font(.system(size: 8, weight: .medium)).foregroundColor(.secondary).frame(height: cellSize)
            }
            .frame(width: 20)
            
            // Grid Columns (weeks)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    ForEach(0..<columns.count, id: \.self) { colIdx in
                        VStack(spacing: spacing) {
                            ForEach(columns[colIdx]) { cell in
                                if cell.date == Date.distantPast {
                                    // Empty padding space
                                    Color.clear
                                        .frame(width: cellSize, height: cellSize)
                                } else {
                                    cellView(for: cell)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func cellView(for cell: ContributionCell) -> some View {
        let color = cellColor(for: cell)
        
        RoundedRectangle(cornerRadius: gridStyle.cornerRadius(cellSize: cellSize))
            .fill(color)
            .frame(width: cellSize, height: cellSize)
            .shadow(color: hoveredCellID == cell.id ? Color.primary.opacity(0.15) : Color.clear, radius: 2, x: 0, y: 1)
            .scaleEffect(hoveredCellID == cell.id ? 1.2 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: hoveredCellID == cell.id)
            .onHover { isHovered in
                if isHovered {
                    hoveredCellID = cell.id
                } else if hoveredCellID == cell.id {
                    hoveredCellID = nil
                }
            }
            .help(tooltipText(for: cell))
            .onTapGesture {
                if cell.isScheduled {
                    onCellSelected(cell.date)
                }
            }
            .accessibilityLabel(accessibilityText(for: cell))
    }
    
    private func cellColor(for cell: ContributionCell) -> Color {
        guard cell.isScheduled else {
            return Color.primary.opacity(0.03) // not active or before start
        }
        
        if cell.completionFraction > 0 {
            // Aggregate heatmap
            return baseColor.opacity(0.15 + (cell.completionFraction * 0.85))
        } else if cell.isCompleted {
            // Binary completed
            return baseColor
        } else {
            // Scheduled but incomplete
            return Color.primary.opacity(0.08)
        }
    }
    
    private func tooltipText(for cell: ContributionCell) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateStr = formatter.string(from: cell.date)
        
        guard cell.isScheduled else {
            return "\(dateStr): Not scheduled"
        }
        
        if cell.completionFraction > 0 {
            let percent = Int(cell.completionFraction * 100)
            return "\(dateStr): \(percent)% complete (\(cell.count) habits completed)"
        } else {
            return "\(dateStr): \(cell.isCompleted ? "Completed" : "Incomplete")"
        }
    }
    
    private func accessibilityText(for cell: ContributionCell) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let dateStr = formatter.string(from: cell.date)
        
        guard cell.isScheduled else {
            return "\(dateStr), not active."
        }
        
        if cell.completionFraction > 0 {
            let percent = Int(cell.completionFraction * 100)
            return "\(dateStr), \(percent) percent completed."
        } else {
            return "\(dateStr), \(cell.isCompleted ? "Completed" : "Incomplete")."
        }
    }
}
