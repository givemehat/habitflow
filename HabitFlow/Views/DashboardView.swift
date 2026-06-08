import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query private var habits: [Habit]
    
    // We instantiate the VM
    @State private var viewModel = DashboardViewModel()
    
    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 14)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dashboard")
                            .font(.system(size: 28, weight: .bold))
                        Text(Date(), style: .date)
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                    Spacer()
                }
                
                if habits.isEmpty {
                    ContentUnavailableView(
                        "No Habits Created",
                        systemImage: "calendar.badge.plus",
                        description: Text("Add a new habit to begin tracking your routines.")
                    )
                    .frame(minHeight: 350)
                } else {
                    let total = viewModel.totalHabits(from: habits)
                    let todayList = viewModel.todayHabits(from: habits)
                    let completedToday = viewModel.todayCompletedHabits(from: habits)
                    let rate = viewModel.todayCompletionRate(from: habits)
                    let currentStreak = viewModel.highestCurrentStreak(from: habits)
                    let longestStreak = viewModel.longestStreakOverall(from: habits)
                    let weeklyScore = viewModel.weeklyScore(from: habits)
                    
                    // Stats Grid
                    LazyVGrid(columns: columns, spacing: 14) {
                        StatCard(
                            title: "Today's Target",
                            value: "\(completedToday.count)/\(todayList.count)",
                            subtitle: "\(todayList.count - completedToday.count) habits left",
                            systemIcon: "checklist",
                            iconColor: .blue,
                            progress: rate
                        )
                        
                        StatCard(
                            title: "Completion Rate",
                            value: "\(Int(rate * 100))%",
                            subtitle: "Today's progress",
                            systemIcon: "percent",
                            iconColor: .green
                        )
                        
                        StatCard(
                            title: "Active Streak",
                            value: "\(currentStreak)d",
                            subtitle: "Highest current streak",
                            systemIcon: "flame.fill",
                            iconColor: .orange,
                            showFlame: currentStreak > 0
                        )
                        
                        StatCard(
                            title: "Longest Streak",
                            value: "\(longestStreak)d",
                            subtitle: "All-time personal record",
                            systemIcon: "trophy.fill",
                            iconColor: .yellow
                        )
                        
                        StatCard(
                            title: "Weekly Score",
                            value: "\(weeklyScore)",
                            subtitle: "Completions past 7 days",
                            systemIcon: "calendar",
                            iconColor: .purple
                        )
                    }
                    
                    // Charts & Insights Row
                    HStack(alignment: .top, spacing: 14) {
                        // Left Column: Apple Charts
                        VStack(spacing: 14) {
                            // Weekly Completions Chart
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Weekly Completion Count")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                let weeklyData = viewModel.weeklyCompletionData(from: habits)
                                Chart {
                                    ForEach(weeklyData) { day in
                                        BarMark(
                                            x: .value("Day", day.dayName),
                                            y: .value("Completions", day.completionCount)
                                        )
                                        .foregroundStyle(Color.blue.gradient)
                                        .cornerRadius(4)
                                    }
                                }
                                .frame(height: 160)
                                .chartYAxis {
                                    AxisMarks(position: .leading)
                                }
                            }
                            .padding(14)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                            
                            // Category Distribution Chart
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Habits by Category")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                let categoriesData = viewModel.categoryDistribution(from: habits)
                                if categoriesData.isEmpty {
                                    Text("No category distribution data").foregroundColor(.secondary)
                                } else {
                                    Chart {
                                        ForEach(categoriesData) { item in
                                            SectorMark(
                                                angle: .value("Habits", item.habitCount),
                                                innerRadius: .ratio(0.6),
                                                angularInset: 1.5
                                            )
                                            .foregroundStyle(Color(hex: item.colorHex))
                                            .annotation(position: .overlay) {
                                                Text("\(item.habitCount)")
                                                    .font(.caption2)
                                                    .bold()
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                    .frame(height: 160)
                                }
                            }
                            .padding(14)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Right Column: Local Insights Panel
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Local Insights")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            let insights = InsightEngine.shared.generateInsights(from: habits)
                            
                            ScrollView {
                                VStack(spacing: 10) {
                                    ForEach(insights) { insight in
                                        HStack(alignment: .top, spacing: 10) {
                                            Image(systemName: insight.systemIcon)
                                                .font(.title3)
                                                .foregroundColor(.blue)
                                                .frame(width: 24, height: 24)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(insight.title)
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                Text(insight.detail)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.primary.opacity(0.03))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .frame(maxHeight: 334)
                        }
                        .padding(14)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                        .frame(width: 320)
                    }
                }
            }
            .padding(20)
        }
    }
}
