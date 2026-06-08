import SwiftUI
import SwiftData

public enum SidebarTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case habits = "Habits"
    case analytics = "Analytics"
    case settings = "Settings"
    
    public var id: String { self.rawValue }
    
    public var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .habits: return "checkmark.circle.fill"
        case .analytics: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct MainSidebarView: View {
    @State private var selectedTab: SidebarTab = .dashboard
    @State private var showingCreateSheet = false
    @State private var showingExportSheet = false
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Section("Menu") {
                    ForEach(SidebarTab.allCases) { tab in
                        NavigationLink(value: tab) {
                            Label(tab.rawValue, systemImage: tab.icon)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 150, ideal: 180, max: 240)
            
            // Add a New Habit button at the bottom of the sidebar
            .safeAreaInset(edge: .bottom) {
                Button(action: { showingCreateSheet = true }) {
                    Label("Add Habit", systemImage: "plus")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(12)
                .background(Color.primary.opacity(0.04))
            }
        } detail: {
            detailView(for: selectedTab)
        }
        // Sheets triggered by shortcuts or buttons
        .sheet(isPresented: $showingCreateSheet) {
            HabitCreationView()
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportPreferenceView()
        }
        // Listeners for Menu / Keyboard Shortcut events
        .onReceive(NotificationCenter.default.publisher(for: .createNewHabit)) { _ in
            showingCreateSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPreferences)) { _ in
            selectedTab = .settings
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportData)) { _ in
            showingExportSheet = true
        }
    }
    
    @ViewBuilder
    private func detailView(for tab: SidebarTab) -> some View {
        switch tab {
        case .dashboard:
            DashboardView()
        case .habits:
            HabitListView()
        case .analytics:
            StatisticsView()
        case .settings:
            PreferencesView()
        }
    }
}

// Temporary wrapper for Export to compile nicely
struct ExportPreferenceView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var habits: [Habit]
    @State private var message: String = ""
    @State private var exportSuccess = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Export Data")
                .font(.headline)
            
            Text("Select where to save your export of \(habits.count) habits and history logs.")
                .font(.body)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button("JSON Format") {
                    export(format: .json)
                }
                Button("CSV Format") {
                    export(format: .csv)
                }
            }
            
            if !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundColor(exportSuccess ? .green : .red)
            }
            
            Button("Done") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding(24)
        .frame(width: 350)
    }
    
    enum ExportFormat {
        case json, csv
    }
    
    private func export(format: ExportFormat) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = format == .json ? [.json] : [.commaSeparatedText]
        savePanel.nameFieldStringValue = "HabitFlow_Backup_\(Int(Date().timeIntervalSince1970))"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    switch format {
                    case .json:
                        if let data = BackupService.shared.generateBackupData(habits: habits) {
                            try data.write(to: url)
                        } else {
                            throw NSError(domain: "export", code: 0, userInfo: [NSLocalizedDescriptionKey: "Encoding failed"])
                        }
                    case .csv:
                        let csvContent = ExportManager.shared.generateCSVString(habits: habits)
                        try csvContent.write(to: url, encoding: .utf8)
                    }
                    exportSuccess = true
                    message = "Exported successfully!"
                } catch {
                    exportSuccess = false
                    message = "Export failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
