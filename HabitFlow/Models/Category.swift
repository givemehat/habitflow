import Foundation
import SwiftData

public enum BuiltInCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case study = "Study"
    case reading = "Reading"
    case fitness = "Fitness"
    case meditation = "Meditation"
    case health = "Health"
    case work = "Work"
    case finance = "Finance"
    case coding = "Coding"
    case languageLearning = "Language Learning"
    case personalGrowth = "Personal Growth"
    
    public var id: String { self.rawValue }
    
    public var icon: String {
        switch self {
        case .study: return "book.fill"
        case .reading: return "books.vertical.fill"
        case .fitness: return "figure.run"
        case .meditation: return "brain.headprofile.peace"
        case .health: return "heart.text.square.fill"
        case .work: return "briefcase.fill"
        case .finance: return "dollarsign.circle.fill"
        case .coding: return "curlybraces"
        case .languageLearning: return "character.bubble.fill"
        case .personalGrowth: return "arrow.up.forward.app.fill"
        }
    }
    
    public var defaultColorHex: String {
        switch self {
        case .study: return "#0A84FF"          // Apple Blue
        case .reading: return "#FF9F0A"        // Apple Orange
        case .fitness: return "#30D158"        // Apple Green
        case .meditation: return "#BF5AF2"     // Apple Purple
        case .health: return "#FF453A"         // Apple Red
        case .work: return "#8E8E93"           // Apple Grey
        case .finance: return "#64D2FF"        // Apple Cyan
        case .coding: return "#FFD60A"         // Apple Yellow
        case .languageLearning: return "#32ADE6" // Apple Light Blue
        case .personalGrowth: return "#FF375F"  // Apple Pink
        }
    }
}

@Model
public final class CustomCategory: Sendable {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var icon: String
    public var colorHex: String
    
    public init(id: UUID = UUID(), name: String, icon: String = "tag.fill", colorHex: String = "#8E8E93") {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
    }
}
