import SwiftUI
import SwiftData
import WidgetKit

struct HabitCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // If editing, this habit is passed in
    let editingHabit: Habit?
    
    @State private var name: String = ""
    @State private var habitDescription: String = ""
    @State private var categoryName: String = BuiltInCategory.study.rawValue
    @State private var icon: String = "checkmark.circle"
    @State private var colorHex: String = "#0A84FF"
    @State private var goalType: GoalType = .daily
    @State private var startDate: Date = Date()
    
    // Goal Type configurations
    @State private var weeklyTargetCount: Int = 3
    @State private var customScheduleDays: Set<Int> = [2, 4, 6] // Mon, Wed, Fri by default (2,4,6)
    
    // Reminders
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = {
        var comp = DateComponents()
        comp.hour = 9
        comp.minute = 0
        return Calendar.current.date(from: comp) ?? Date()
    }()
    @State private var reminderDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
    
    // Presets
    private let colorPresets = [
        "#0A84FF", // Blue
        "#30D158", // Green
        "#FF9F0A", // Orange
        "#BF5AF2", // Purple
        "#FF453A", // Red
        "#FFD60A", // Yellow
        "#64D2FF", // Cyan
        "#FF375F"  // Pink
    ]
    
    private let iconPresets = [
        "checkmark.circle.fill", "book.fill", "books.vertical.fill", "figure.run",
        "brain.headprofile.peace", "heart.fill", "briefcase.fill", "dollarsign.circle.fill",
        "curlybraces", "character.bubble.fill", "arrow.up.forward.app.fill", "music.note",
        "drop.fill", "bed.double.fill", "guitars.fill", "bicycle", "paintpalette.fill", "camera.fill"
    ]
    
    @Query private var customCategories: [CustomCategory]
    
    public init(editingHabit: Habit? = nil) {
        self.editingHabit = editingHabit
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Description (Optional)", text: $habitDescription)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("Category", selection: $categoryName) {
                        Section("Default Categories") {
                            ForEach(BuiltInCategory.allCases) { cat in
                                Label(cat.rawValue, systemImage: cat.icon).tag(cat.rawValue)
                            }
                        }
                        
                        if !customCategories.isEmpty {
                            Section("Custom Categories") {
                                ForEach(customCategories) { cat in
                                    Label(cat.name, systemImage: cat.icon).tag(cat.name)
                                }
                            }
                        }
                    }
                }
                
                Section("Aesthetic Customization") {
                    // Custom Presets
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Theme Color").font(.subheadline).foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            ForEach(colorPresets, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: colorHex == hex ? 2 : 0)
                                    )
                                    .onTapGesture {
                                        colorHex = hex
                                    }
                            }
                            // Custom System Color Picker
                            ColorPicker("", selection: Binding(
                                get: { Color(hex: colorHex) },
                                set: { newColor in
                                    if let hex = newColor.toHex() {
                                        colorHex = hex
                                    }
                                }
                            ))
                            .labelsHidden()
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // Icon Preset
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Symbol Icon").font(.subheadline).foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(iconPresets, id: \.self) { sym in
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(icon == sym ? Color(hex: colorHex).opacity(0.15) : Color.clear)
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color(hex: colorHex), lineWidth: icon == sym ? 1.5 : 0)
                                            )
                                        
                                        Image(systemName: sym)
                                            .font(.subheadline)
                                            .foregroundColor(icon == sym ? Color(hex: colorHex) : .primary)
                                    }
                                    .onTapGesture {
                                        icon = sym
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Goal & Schedule") {
                    Picker("Goal Type", selection: $goalType) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    if goalType == .weekly {
                        Stepper(value: $weeklyTargetCount, in: 1...7) {
                            Text("Target count: \(weeklyTargetCount) days per week")
                        }
                    } else if goalType == .customSchedule {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Active Weekdays").font(.subheadline).foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                let days = [
                                    (1, "S"), (2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S")
                                ]
                                ForEach(days, id: \.0) { num, name in
                                    Text(name)
                                        .frame(width: 24, height: 24)
                                        .background(customScheduleDays.contains(num) ? Color(hex: colorHex) : Color.primary.opacity(0.06))
                                        .foregroundColor(customScheduleDays.contains(num) ? .white : .primary)
                                        .cornerRadius(4)
                                        .font(.caption)
                                        .bold()
                                        .onTapGesture {
                                            if customScheduleDays.contains(num) {
                                                if customScheduleDays.count > 1 {
                                                    customScheduleDays.remove(num)
                                                }
                                            } else {
                                                customScheduleDays.insert(num)
                                            }
                                        }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
                }
                
                Section("Reminders") {
                    Toggle("Enable Notification Reminder", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { _, enabled in
                            if enabled {
                                NotificationManager.shared.requestAuthorization { granted in
                                    if !granted {
                                        DispatchQueue.main.async {
                                            reminderEnabled = false
                                        }
                                    }
                                }
                            }
                        }
                    
                    if reminderEnabled {
                        DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: [.hourAndMinute])
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Reminder Weekdays").font(.subheadline).foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                let days = [
                                    (1, "S"), (2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S")
                                ]
                                ForEach(days, id: \.0) { num, name in
                                    Text(name)
                                        .frame(width: 24, height: 24)
                                        .background(reminderDays.contains(num) ? Color(hex: colorHex) : Color.primary.opacity(0.06))
                                        .foregroundColor(reminderDays.contains(num) ? .white : .primary)
                                        .cornerRadius(4)
                                        .font(.caption)
                                        .bold()
                                        .onTapGesture {
                                            if reminderDays.contains(num) {
                                                if reminderDays.count > 1 {
                                                    reminderDays.remove(num)
                                                }
                                            } else {
                                                reminderDays.insert(num)
                                            }
                                        }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(editingHabit == nil ? "New Habit" : "Edit Habit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveHabit()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .onAppear(perform: populateDataIfEditing)
            .frame(width: 450, height: 500)
        }
    }
    
    private func populateDataIfEditing() {
        guard let edit = editingHabit else { return }
        name = edit.name
        habitDescription = edit.habitDescription
        categoryName = edit.categoryName
        icon = edit.icon
        colorHex = edit.colorHex
        goalType = edit.goalType
        startDate = edit.startDate
        weeklyTargetCount = edit.weeklyTargetCount
        customScheduleDays = Set(edit.customScheduleDays)
        
        // Populate reminder values
        reminderEnabled = edit.reminderEnabled
        var comp = DateComponents()
        comp.hour = edit.reminderHour
        comp.minute = edit.reminderMinute
        reminderTime = Calendar.current.date(from: comp) ?? Date()
        
        let days = edit.reminderDays
        if !days.isEmpty {
            reminderDays = Set(days)
        }
    }
    
    private func saveHabit() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let targetDays = goalType == .customSchedule ? Array(customScheduleDays).sorted() : []
        let reminderHour = Calendar.current.component(.hour, from: reminderTime)
        let reminderMinute = Calendar.current.component(.minute, from: reminderTime)
        let daysArray = Array(reminderDays).sorted()
        
        let savedHabit: Habit
        
        if let edit = editingHabit {
            // Edit existing
            edit.name = trimmedName
            edit.habitDescription = habitDescription
            edit.categoryName = categoryName
            edit.icon = icon
            edit.colorHex = colorHex
            edit.goalTypeRaw = goalType.rawValue
            edit.startDate = Calendar.current.startOfDay(for: startDate)
            edit.weeklyTargetCount = weeklyTargetCount
            edit.customScheduleDays = targetDays
            
            edit.reminderEnabled = reminderEnabled
            edit.reminderHour = reminderHour
            edit.reminderMinute = reminderMinute
            edit.reminderDays = daysArray
            
            savedHabit = edit
        } else {
            // Create new
            let newHabit = Habit(
                id: UUID(),
                name: trimmedName,
                habitDescription: habitDescription,
                categoryName: categoryName,
                icon: icon,
                colorHex: colorHex,
                goalType: goalType,
                customScheduleDays: targetDays,
                weeklyTargetCount: weeklyTargetCount,
                startDate: startDate,
                reminderEnabled: reminderEnabled,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                reminderDays: daysArray
            )
            modelContext.insert(newHabit)
            savedHabit = newHabit
        }
        
        // Configure Local Alerts
        NotificationManager.shared.cancelReminders(for: savedHabit.id)
        if reminderEnabled {
            NotificationManager.shared.scheduleReminder(
                habitId: savedHabit.id,
                habitName: savedHabit.name,
                body: "Time to complete your habit: \(savedHabit.name)!",
                hour: reminderHour,
                minute: reminderMinute,
                weekdays: daysArray
            )
        }
        
        do {
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
            dismiss()
        } catch {
            print("Failed to save habit: \(error.localizedDescription)")
        }
    }
}
