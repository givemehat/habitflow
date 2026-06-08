import SwiftUI

public struct StatCard: View {
    public let title: String
    public let value: String
    public let subtitle: String?
    public let systemIcon: String
    public let iconColor: Color
    
    // Optional indicators
    public var progress: Double? = nil // 0.0 to 1.0
    public var showFlame: Bool = false
    
    public init(
        title: String,
        value: String,
        subtitle: String? = nil,
        systemIcon: String,
        iconColor: Color = .blue,
        progress: Double? = nil,
        showFlame: Bool = false
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.systemIcon = systemIcon
        self.iconColor = iconColor
        self.progress = progress
        self.showFlame = showFlame
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Text(value)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        if showFlame {
                            Image(systemName: "flame.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                                .transition(.scale)
                                .accessibilityLabel("Streak active")
                        }
                    }
                }
                
                Spacer()
                
                // Icon circle
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 38, height: 38)
                    
                    Image(systemName: systemIcon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(iconColor)
                }
            }
            
            if let progress = progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.06))
                            .frame(height: 5)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [iconColor, iconColor.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(min(max(progress, 0.0), 1.0)), height: 5)
                    }
                }
                .frame(height: 5)
                .padding(.top, 4)
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, progress != nil ? 4 : 0)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value). \(subtitle ?? "")")
    }
}
