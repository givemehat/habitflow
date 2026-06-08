import Foundation
import PDFKit
import AppKit

public final class PDFReportGenerator: Sendable {
    public static let shared = PDFReportGenerator()
    
    private init() {}
    
    // Generates a crisp, vectorized PDF report summarizing habit metrics.
    // It automatically handles pagination for multi-page reports.
    @MainActor
    public func createReportPDF(habits: [Habit]) -> Data {
        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData) else { return Data() }
        
        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792) // Letter size: 8.5" x 11"
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return Data() }
        
        context.beginPage(mediaBox: &mediaBox)
        
        // Establish NSGraphicsContext for drawing text and vectors
        let previousContext = NSGraphicsContext.current
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        
        // Header Title
        let title = "HabitFlow Progress Report"
        let titleFont = NSFont.boldSystemFont(ofSize: 22)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: NSColor.labelColor
        ]
        title.draw(at: CGPoint(x: 54, y: 720), withAttributes: titleAttributes)
        
        // Timestamp Subtitle
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        let subtitle = "Report generated on \(formatter.string(from: Date()))"
        let subtitleFont = NSFont.systemFont(ofSize: 10)
        subtitle.draw(at: CGPoint(x: 54, y: 700), withAttributes: [
            .font: subtitleFont,
            .foregroundColor: NSColor.secondaryLabelColor
        ])
        
        // Separator rule
        context.setStrokeColor(NSColor.separatorColor.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: 54, y: 685))
        context.addLine(to: CGPoint(x: 558, y: 685))
        context.strokePath()
        
        // Summary Block
        let summaryText = "Total Habits Tracked: \(habits.count)     Active Streaks Sum: \(habits.map({ $0.calculateCurrentStreak() }).reduce(0, +)) days"
        summaryText.draw(at: CGPoint(x: 54, y: 660), withAttributes: [
            .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: NSColor.labelColor
        ])
        
        // Table Headers
        var currentY: CGFloat = 620
        let headerFont = NSFont.boldSystemFont(ofSize: 11)
        let headerAttrs: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: NSColor.secondaryLabelColor]
        
        "Habit".draw(at: CGPoint(x: 54, y: currentY), withAttributes: headerAttrs)
        "Category".draw(at: CGPoint(x: 210, y: currentY), withAttributes: headerAttrs)
        "Schedule".draw(at: CGPoint(x: 320, y: currentY), withAttributes: headerAttrs)
        "Streak".draw(at: CGPoint(x: 430, y: currentY), withAttributes: headerAttrs)
        "Logs Count".draw(at: CGPoint(x: 500, y: currentY), withAttributes: headerAttrs)
        
        currentY -= 15
        context.move(to: CGPoint(x: 54, y: currentY + 5))
        context.addLine(to: CGPoint(x: 558, y: currentY + 5))
        context.strokePath()
        
        let rowFont = NSFont.systemFont(ofSize: 10)
        let rowAttrs: [NSAttributedString.Key: Any] = [.font: rowFont, .foregroundColor: NSColor.labelColor]
        
        for habit in habits {
            currentY -= 20
            
            // Check for page-break height
            if currentY < 60 {
                context.endPage()
                context.beginPage(mediaBox: &mediaBox)
                NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
                currentY = 720
                
                // Draw brief header on new page
                "Habit (Continued)".draw(at: CGPoint(x: 54, y: currentY), withAttributes: headerAttrs)
                currentY -= 15
                context.move(to: CGPoint(x: 54, y: currentY + 5))
                context.addLine(to: CGPoint(x: 558, y: currentY + 5))
                context.strokePath()
                currentY -= 20
            }
            
            // Clip name to fit column width
            let name = habit.name.count > 25 ? String(habit.name.prefix(22)) + "..." : habit.name
            name.draw(at: CGPoint(x: 54, y: currentY), withAttributes: rowAttrs)
            habit.categoryName.draw(at: CGPoint(x: 210, y: currentY), withAttributes: rowAttrs)
            habit.goalType.rawValue.draw(at: CGPoint(x: 320, y: currentY), withAttributes: rowAttrs)
            
            let streak = "\(habit.calculateCurrentStreak()) days"
            streak.draw(at: CGPoint(x: 430, y: currentY), withAttributes: rowAttrs)
            
            let logsStr = "\(habit.logs.count)"
            logsStr.draw(at: CGPoint(x: 500, y: currentY), withAttributes: rowAttrs)
        }
        
        context.endPage()
        context.close()
        
        NSGraphicsContext.current = previousContext
        return pdfData as Data
    }
}
