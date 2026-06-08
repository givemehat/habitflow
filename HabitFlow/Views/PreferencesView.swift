import SwiftUI
import SwiftData
import WidgetKit

struct PreferencesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var customCategories: [CustomCategory]
    @Query private var habits: [Habit]
    
    @ObservedObject private var prefsManager = PreferencesManager.shared
    
    // Custom Category Input States
    @State private var newCategoryName = ""
    @State private var newCategoryIcon = "tag.fill"
    @State private var newCategoryColor = "#FF375F"
    @State private var showingAddCategoryPopover = false
    
    // Backup & Restore States
    @State private var importResultText = ""
    @State private var importMergeMode = "Merge" // Merge or Overwrite
    @State private var showingResetConfirmation = false
    
    // Local backup list
    @State private var localBackups: [URL] = []
    
    private let presetIcons = ["tag.fill", "star.fill", "bolt.fill", "flame.fill", "crown.fill", "heart.fill", "gamecontroller.fill", "cup.and.saucer.fill"]
    private let presetColors = ["#FF375F", "#FF9F0A", "#FFD60A", "#30D158", "#0A84FF", "#BF5AF2", "#8E8E93"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Text("Preferences")
                    .font(.system(size: 28, weight: .bold))
                
                // Section 1: Appearance Customization
                VStack(alignment: .leading, spacing: 14) {
                    Text("Appearance")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Form {
                        Picker("Layout Density", selection: $prefsManager.preferences.layoutDensity) {
                            ForEach(LayoutDensity.allCases, id: \.self) { density in
                                Text(density.rawValue).tag(density)
                            }
                        }
                        .onChange(of: prefsManager.preferences.layoutDensity) { _, _ in prefsManager.savePreferences() }
                        
                        Picker("Heatmap Grid Style", selection: $prefsManager.preferences.gridStyle) {
                            ForEach(GridStyle.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .onChange(of: prefsManager.preferences.gridStyle) { _, _ in prefsManager.savePreferences() }
                        
                        Slider(value: $prefsManager.preferences.cornerRadius, in: 2.0...14.0, step: 1.0) {
                            Text("Corner Radius: \(Int(prefsManager.preferences.cornerRadius))px")
                        }
                        .onChange(of: prefsManager.preferences.cornerRadius) { _, _ in prefsManager.savePreferences() }
                        
                        Picker("Interactive Widget Theme", selection: $prefsManager.preferences.widgetTheme) {
                            ForEach(WidgetThemeType.allCases, id: \.self) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                        .onChange(of: prefsManager.preferences.widgetTheme) { _, _ in
                            prefsManager.savePreferences()
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                
                // Section 2: Custom Categories
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Custom Categories")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                        Button(action: { showingAddCategoryPopover = true }) {
                            Label("New Category", systemImage: "plus")
                        }
                        .popover(isPresented: $showingAddCategoryPopover) {
                            VStack(spacing: 12) {
                                Text("New Custom Category").font(.headline)
                                
                                TextField("Category Name", text: $newCategoryName)
                                    .textFieldStyle(.roundedBorder)
                                
                                // Color Selector
                                HStack {
                                    ForEach(presetColors, id: \.self) { hex in
                                        Circle()
                                            .fill(Color(hex: hex))
                                            .frame(width: 20, height: 20)
                                            .overlay(Circle().stroke(Color.primary, lineWidth: newCategoryColor == hex ? 1.5 : 0))
                                            .onTapGesture { newCategoryColor = hex }
                                    }
                                }
                                
                                // Icon Selector
                                HStack {
                                    ForEach(presetIcons, id: \.self) { icon in
                                        Image(systemName: icon)
                                            .font(.title3)
                                            .padding(6)
                                            .background(newCategoryIcon == icon ? Color.primary.opacity(0.12) : Color.clear)
                                            .cornerRadius(6)
                                            .onTapGesture { newCategoryIcon = icon }
                                    }
                                }
                                
                                HStack {
                                    Button("Cancel") { showingAddCategoryPopover = false }
                                    Button("Create") {
                                        createCustomCategory()
                                    }
                                    .disabled(newCategoryName.isEmpty)
                                }
                            }
                            .padding(14)
                            .frame(width: 250)
                        }
                    }
                    
                    if customCategories.isEmpty {
                        Text("No custom categories created. Add one above to personalize your habit tags.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        FlowLayout(spacing: 8) {
                            ForEach(customCategories) { cat in
                                HStack(spacing: 4) {
                                    Image(systemName: cat.icon)
                                    Text(cat.name)
                                    Button(action: {
                                        modelContext.delete(cat)
                                        try? modelContext.save()
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: cat.colorHex).opacity(0.15))
                                .foregroundColor(Color(hex: cat.colorHex))
                                .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                
                // Section 3: Backup & Restore
                VStack(alignment: .leading, spacing: 14) {
                    Text("Local Backup & Restore")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Automated Weekly Auto-Backups", isOn: $prefsManager.preferences.autoBackupEnabled)
                            .onChange(of: prefsManager.preferences.autoBackupEnabled) { _, _ in prefsManager.savePreferences() }
                        
                        HStack(spacing: 12) {
                            Button("Create Manual Backup") {
                                let success = BackupService.shared.createBackup(
                                    habits: habits,
                                    filename: "manual_backup_\(Int(Date().timeIntervalSince1970)).json"
                                )
                                if success {
                                    importResultText = "Backup created successfully!"
                                    loadBackupsList()
                                } else {
                                    importResultText = "Failed to create backup."
                                }
                            }
                            
                            Button("Import Backup File...") {
                                selectAndImportBackup()
                            }
                        }
                        
                        Picker("Merge Conflict Resolution", selection: $importMergeMode) {
                            Text("Merge (Keep history logs, add missing habits)").tag("Merge")
                            Text("Overwrite (Replace settings and update details)").tag("Overwrite")
                        }
                        .pickerStyle(.inline)
                        .controlSize(.small)
                        
                        if !importResultText.isEmpty {
                            Text(importResultText)
                                .font(.caption)
                                .foregroundColor(importResultText.contains("successfully") ? .green : .red)
                        }
                        
                        if !localBackups.isEmpty {
                            Text("Available Local Backups:")
                                .font(.subheadline)
                                .bold()
                                .padding(.top, 4)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(localBackups, id: \.self) { url in
                                    HStack {
                                        Text(url.lastPathComponent)
                                            .font(.caption)
                                        Spacer()
                                        Button("Restore") {
                                            if let data = try? Data(contentsOf: url) {
                                                let ok = BackupService.shared.restore(from: data, into: modelContext, mergeMode: importMergeMode)
                                                importResultText = ok ? "Restored backup successfully!" : "Restore failed."
                                            }
                                        }
                                        .controlSize(.small)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                
                // Section 4: Data Reset
                VStack(alignment: .leading, spacing: 10) {
                    Text("Danger Zone")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Button("Reset All Application Data", role: .destructive) {
                        showingResetConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.2), lineWidth: 1))
            }
            .padding(20)
        }
        .onAppear {
            loadBackupsList()
        }
        .confirmationDialog("Reset All Data?", isPresented: $showingResetConfirmation) {
            Button("Delete Everything", role: .destructive) {
                resetDatabase()
            }
        } message: {
            Text("This will permanently delete all habits, log history, and custom categories. This cannot be undone.")
        }
    }
    
    private func loadBackupsList() {
        localBackups = BackupService.shared.listLocalBackups()
    }
    
    private func createCustomCategory() {
        let cat = CustomCategory(name: newCategoryName, icon: newCategoryIcon, colorHex: newCategoryColor)
        modelContext.insert(cat)
        try? modelContext.save()
        
        newCategoryName = ""
        showingAddCategoryPopover = false
    }
    
    private func selectAndImportBackup() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                do {
                    let data = try Data(contentsOf: url)
                    let ok = BackupService.shared.restore(from: data, into: modelContext, mergeMode: importMergeMode)
                    importResultText = ok ? "Backup imported successfully!" : "Invalid backup file structure."
                    WidgetCenter.shared.reloadAllTimelines()
                } catch {
                    importResultText = "Import failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func resetDatabase() {
        // Clear all habits and logs
        try? modelContext.delete(model: Habit.self)
        try? modelContext.delete(model: HabitLog.self)
        try? modelContext.delete(model: CustomCategory.self)
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        
        importResultText = "Application data cleared successfully."
        loadBackupsList()
    }
}

// Simple Layout helper for flowing custom category badges horizontally
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 300
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > width {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }
        height = currentY + rowHeight
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }
    }
}
