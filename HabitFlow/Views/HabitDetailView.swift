import SwiftUI
import SwiftData

struct HabitDetailView: View {
    let habit: Habit
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditSheet = false
    @State private var editingLogNotesId: UUID? = nil
    @State private var currentNotesText: String = ""
    @State private var showDeleteConfirmation = false
    
    private var completionRate30Days: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var scheduledDays = 0
        var completedDays = 0
        
        for i in 0..<30 {
            guard let checkDate = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            if habit.isScheduled(on: checkDate) {
                scheduledDays += 1
                if habit.isCompleted(on: checkDate) {
                    completedDays += 1
                }
            }
        }
        
        guard scheduledDays > 0 else { return 0.0 }
        return Double(completedDays) / Double(scheduledDays)
    }
    
    private var reminderTimeString: String {
        var components = DateComponents()
        components.hour = habit.reminderHour
        components.minute = habit.reminderMinute
        guard let timeDate = Calendar.current.date(from: components) else { return "" }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeStr = formatter.string(from: timeDate)
        
        let days = habit.reminderDays
        if days.count == 7 {
            return "Daily at \(timeStr)"
        } else if days.isEmpty {
            return "At \(timeStr)"
        } else {
            let daysStr = days.map { dayNum -> String in
                switch dayNum {
                case 1: return "Sun"
                case 2: return "Mon"
                case 3: return "Tue"
                case 4: return "Wed"
                case 5: return "Thu"
                case 6: return "Fri"
                case 7: return "Sat"
                default: return ""
                }
            }.filter { !$0.isEmpty }.joined(separator: ", ")
            return "\(daysStr) at \(timeStr)"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Panel
                HStack(alignment: .top) {
                    // Habit Info
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: habit.colorHex).opacity(0.12))
                                .frame(width: 54, height: 54)
                            Image(systemName: habit.icon)
                                .font(.system(size: 24))
                                .foregroundColor(Color(hex: habit.colorHex))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(habit.name)
                                .font(.system(size: 24, weight: .bold))
                            
                            if !habit.habitDescription.isEmpty {
                                Text(habit.habitDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 8) {
                                Text(habit.categoryName)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: habit.colorHex).opacity(0.15))
                                    .foregroundColor(Color(hex: habit.colorHex))
                                    .cornerRadius(4)
                                
                                Text(habit.goalType.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if habit.reminderEnabled {
                                    HStack(spacing: 3) {
                                        Image(systemName: "bell.fill")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(reminderTimeString)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Actions
                    HStack(spacing: 8) {
                        Button("Edit Habit") {
                            showingEditSheet = true
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Delete", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
                .padding(.bottom, 10)
                
                // Habit Stats Grid
                let totalCompletions = habit.logs.count
                let currentStreak = habit.calculateCurrentStreak()
                let longestStreak = habit.calculateLongestStreak()
                let rate30Days = completionRate30Days
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ]) {
                    StatCard(
                        title: "Current Streak",
                        value: "\(currentStreak) days",
                        systemIcon: "flame.fill",
                        iconColor: .orange,
                        showFlame: currentStreak > 0
                    )
                    StatCard(
                        title: "Longest Streak",
                        value: "\(longestStreak) days",
                        systemIcon: "trophy.fill",
                        iconColor: .yellow
                    )
                    StatCard(
                        title: "Total Logs",
                        value: "\(totalCompletions)",
                        systemIcon: "square.and.pencil",
                        iconColor: .blue
                    )
                    StatCard(
                        title: "30-Day Completion",
                        value: "\(Int(rate30Days * 100))%",
                        systemIcon: "chart.pie.fill",
                        iconColor: .green
                    )
                }
                
                // Contribution Heatmap
                MonthlyHeatmapView(habit: habit)
                
                // Completion History Table
                VStack(alignment: .leading, spacing: 12) {
                    Text("Completion History")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    let sortedLogs = habit.logs.sorted(by: { $0.date > $1.date })
                    
                    if sortedLogs.isEmpty {
                        Text("No logs recorded. Check off this habit to begin your journal.")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 0) {
                            // Header row
                            HStack {
                                Text("Date").frame(width: 150, alignment: .leading)
                                Text("Notes").frame(maxWidth: .infinity, alignment: .leading)
                                Spacer()
                                Text("Actions").frame(width: 80, alignment: .trailing)
                            }
                            .font(.caption)
                            .bold()
                            .foregroundColor(.secondary)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(Color.primary.opacity(0.04))
                            
                            Divider()
                            
                            ForEach(sortedLogs) { log in
                                HStack {
                                    // Log Date
                                    Text(log.date, style: .date)
                                        .frame(width: 150, alignment: .leading)
                                        .font(.subheadline)
                                    
                                    // Notes Column
                                    if editingLogNotesId == log.id {
                                        TextField("Add completion notes...", text: $currentNotesText)
                                            .textFieldStyle(.roundedBorder)
                                            .onSubmit {
                                                let vm = HabitDetailViewModel()
                                                vm.updateNotes(for: log, notes: currentNotesText, in: modelContext)
                                                editingLogNotesId = nil
                                            }
                                    } else {
                                        Text(log.notes.isEmpty ? "No notes" : log.notes)
                                            .font(.subheadline)
                                            .foregroundColor(log.notes.isEmpty ? .secondary : .primary)
                                            .italic(log.notes.isEmpty)
                                            .onTapGesture {
                                                currentNotesText = log.notes
                                                editingLogNotesId = log.id
                                            }
                                    }
                                    
                                    Spacer()
                                    
                                    // Action buttons
                                    HStack(spacing: 8) {
                                        // Edit Notes button
                                        Button(action: {
                                            if editingLogNotesId == log.id {
                                                let vm = HabitDetailViewModel()
                                                vm.updateNotes(for: log, notes: currentNotesText, in: modelContext)
                                                editingLogNotesId = nil
                                            } else {
                                                currentNotesText = log.notes
                                                editingLogNotesId = log.id
                                            }
                                        }) {
                                            Image(systemName: editingLogNotesId == log.id ? "checkmark.circle" : "pencil")
                                                .foregroundColor(.blue)
                                        }
                                        .buttonStyle(.plain)
                                        .help(editingLogNotesId == log.id ? "Save notes" : "Edit notes")
                                        
                                        // Delete Log button
                                        Button(action: {
                                            let vm = HabitDetailViewModel()
                                            vm.deleteLog(for: habit, log: log, in: modelContext)
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                        .help("Delete completion log")
                                    }
                                    .frame(width: 80, alignment: .trailing)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 8)
                                
                                Divider()
                            }
                        }
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                    }
                }
            }
            .padding(20)
        }
        .sheet(isPresented: $showingEditSheet) {
            HabitCreationView(editingHabit: habit)
        }
        .confirmationDialog(
            "Are you sure you want to delete this habit?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Habit", role: .destructive) {
                NotificationManager.shared.cancelReminders(for: habit.id)
                modelContext.delete(habit)
                try? modelContext.save()
                WidgetCenter.shared.reloadAllTimelines()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove the habit and all of its \(habit.logs.count) completion logs. This action cannot be undone.")
        }
    }
}
