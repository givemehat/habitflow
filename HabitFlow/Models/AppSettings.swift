import Foundation
import SwiftUI

public enum WidgetThemeType: String, Codable, CaseIterable {
    case minimal = "Minimal"
    case glass = "Glass"
    case monochrome = "Monochrome"
    case github = "GitHub Style"
    case appleNotes = "Apple Notes Style"
}

public enum LayoutDensity: String, Codable, CaseIterable {
    case compact = "Compact"
    case comfortable = "Comfortable"
    case spacious = "Spacious"
    
    public var padding: CGFloat {
        switch self {
        case .compact: return 4
        case .comfortable: return 8
        case .spacious: return 14
        }
    }
}

public enum GridStyle: String, Codable, CaseIterable {
    case rounded = "Rounded"
    case square = "Square"
    case circles = "Circles"
    
    public func cornerRadius(cellSize: CGFloat) -> CGFloat {
        switch self {
        case .rounded: return cellSize * 0.22
        case .square: return 0
        case .circles: return cellSize / 2
        }
    }
}

public struct AppPreferences: Codable, Sendable {
    public var accentColorHex: String = "#0A84FF" // Default Blue
    public var widgetTheme: WidgetThemeType = .minimal
    public var fontFamily: String = "System"
    public var cornerRadius: Double = 8.0
    public var layoutDensity: LayoutDensity = .comfortable
    public var gridStyle: GridStyle = .rounded
    
    // Backup and Sync settings
    public var autoBackupEnabled: Bool = true
    public var lastBackupDate: Date? = nil
    
    public init() {}
}

// UserDefaults Manager for Shared preferences across app and widgets
public final class PreferencesManager: ObservableObject, @unchecked Sendable {
    public static let shared = PreferencesManager()
    
    private let suiteName = "group.com.habitflow.shared"
    private let preferencesKey = "habitflow_preferences"
    
    @Published public var preferences = AppPreferences()
    
    private init() {
        loadPreferences()
    }
    
    public func loadPreferences() {
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        if let data = defaults.data(forKey: preferencesKey),
           let decoded = try? JSONDecoder().decode(AppPreferences.self, from: data) {
            self.preferences = decoded
        }
    }
    
    public func savePreferences() {
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        if let encoded = try? JSONEncoder().encode(preferences) {
            defaults.set(encoded, forKey: preferencesKey)
            defaults.synchronize()
        }
    }
}

// SwiftUI Color extension for HEX conversion
extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    public func toHex() -> String? {
        // Fallback for simple conversion
        guard let components = NSColor(self).usingColorSpace(.sRGB)?.cgColor.components else { return nil }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        let a = components.count > 3 ? Float(components[3]) : 1.0
        
        if a < 1.0 {
            return String(format: "#%02lX%02lX%02lX%02lX", lroundf(a * 255), lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}
