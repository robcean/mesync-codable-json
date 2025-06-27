//
//  HabitsView.swift
//  meSync
//
//  Vista dedicada para gestionar todos los hábitos
//

import SwiftUI

struct HabitsView: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var quickAddState: QuickAddState
    
    // View states
    @State private var selectedFrequency: HabitFrequency?
    @State private var searchText = ""
    @State private var showingCalendar = false
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            // Content
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Calendar view toggle
                    calendarToggle
                    
                    // Calendar (if showing)
                    if showingCalendar {
                        calendarSection
                    }
                    
                    // Stats
                    statsSection
                    
                    // Frequency filter
                    frequencyFilter
                    
                    // Search bar
                    searchBar
                    
                    // Habits list
                    habitsList
                }
                .padding(.top, AppSpacing.md)
            }
        }
        .mainContainerStyle()
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Text("Habits")
                .sectionTitleStyle()
            
            Spacer()
            
            // Add new habit button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    quickAddState = .habitForm(editingHabit: nil)
                }
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: AppDimensions.mediumIcon))
                    .foregroundStyle(AppColors.primary)
            }
            .pressableStyle()
        }
        .headerContainerStyle()
    }
    
    // MARK: - Calendar Toggle
    private var calendarToggle: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingCalendar.toggle()
            }
        }) {
            HStack {
                Image(systemName: showingCalendar ? "calendar.badge.checkmark" : "calendar")
                    .font(.system(size: AppDimensions.smallIcon))
                
                Text(showingCalendar ? "Hide Calendar" : "Show Calendar")
                    .font(AppTypography.body)
                
                Spacer()
                
                Image(systemName: showingCalendar ? "chevron.up" : "chevron.down")
                    .font(.caption)
            }
            .foregroundStyle(AppColors.primary)
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
        }
        .pressableStyle()
        .standardHorizontalPadding()
    }
    
    // MARK: - Calendar Section
    private var calendarSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Month header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: AppDimensions.smallIcon))
                }
                .pressableStyle()
                
                Spacer()
                
                Text(monthYearString)
                    .font(AppTypography.bodyMedium)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: AppDimensions.smallIcon))
                }
                .pressableStyle()
            }
            .foregroundStyle(AppColors.primaryText)
            
            // Calendar grid
            CalendarGrid(
                selectedDate: $selectedDate,
                habits: dataManager.habits,
                habitInstances: dataManager.habitInstances
            )
        }
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
        .standardHorizontalPadding()
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: AppSpacing.md) {
            StatCard(
                title: "Active",
                value: "\(dataManager.habits.count)",
                icon: "repeat",
                color: AppColors.primary
            )
            
            StatCard(
                title: "Today",
                value: "\(todayHabitsCount)",
                icon: "calendar.day.timeline.left",
                color: .blue
            )
            
            StatCard(
                title: "Streak",
                value: "\(longestStreak)",
                icon: "flame",
                color: .orange
            )
        }
        .standardHorizontalPadding()
    }
    
    // MARK: - Frequency Filter
    private var frequencyFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                FilterChip(
                    title: "All",
                    isSelected: selectedFrequency == nil,
                    action: { selectedFrequency = nil }
                )
                
                ForEach(HabitFrequency.allCases, id: \.self) { frequency in
                    FilterChip(
                        title: frequency.rawValue,
                        isSelected: selectedFrequency == frequency,
                        action: { selectedFrequency = frequency }
                    )
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.tertiaryText)
            
            TextField("Search habits...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
        .standardHorizontalPadding()
    }
    
    // MARK: - Habits List
    private var habitsList: some View {
        LazyVStack(spacing: AppSpacing.md) {
            if filteredHabits.isEmpty {
                emptyStateView
            } else {
                ForEach(filteredHabits) { habit in
                    HabitRow(
                        habit: habit,
                        quickAddState: $quickAddState,
                        onDelete: {
                            withAnimation {
                                dataManager.deleteHabit(habit)
                            }
                        }
                    )
                }
            }
        }
        .standardHorizontalPadding()
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "repeat.circle")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.secondaryText)
            
            Text("No habits found")
                .subtitleStyle()
            
            Text("Create your first habit to build better routines")
                .captionStyle()
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, AppSpacing.xxxl)
    }
    
    // MARK: - Computed Properties
    private var filteredHabits: [HabitModel] {
        var habits = dataManager.habits
        
        // Apply frequency filter
        if let frequency = selectedFrequency {
            habits = habits.filter { $0.frequency == frequency }
        }
        
        // Apply search
        if !searchText.isEmpty {
            habits = habits.filter { habit in
                habit.name.localizedCaseInsensitiveContains(searchText) ||
                habit.habitDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return habits.sorted { $0.name < $1.name }
    }
    
    private var todayHabitsCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return dataManager.habits.filter { habit in
            shouldHabitOccurOn(habit: habit, date: today)
        }.count
    }
    
    private var longestStreak: Int {
        // Simplified streak calculation - would need more complex logic in production
        let recentCompletions = dataManager.habitInstances
            .filter { $0.isCompleted }
            .sorted { $0.scheduledDate > $1.scheduledDate }
            .prefix(30)
        
        return recentCompletions.count
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    // MARK: - Actions
    private func previousMonth() {
        withAnimation {
            selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        }
    }
    
    private func nextMonth() {
        withAnimation {
            selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
        }
    }
    
    private func shouldHabitOccurOn(habit: HabitModel, date: Date) -> Bool {
        // Reuse logic from ItemsListView
        let calendar = Calendar.current
        let habitStartDate = calendar.startOfDay(for: habit.remindAt)
        let targetDate = calendar.startOfDay(for: date)
        
        guard targetDate >= habitStartDate else { return false }
        
        switch habit.frequency {
        case .noRepetition:
            return calendar.isDate(targetDate, inSameDayAs: habitStartDate)
        case .daily:
            let daysDifference = calendar.dateComponents([.day], from: habitStartDate, to: targetDate).day ?? 0
            return daysDifference % habit.dailyInterval == 0
        case .weekly:
            let weekday = calendar.component(.weekday, from: targetDate)
            let adjustedWeekday = weekday == 1 ? 7 : weekday - 1
            return habit.selectedWeekdays.contains(adjustedWeekday)
        case .monthly:
            let dayOfMonth = calendar.component(.day, from: targetDate)
            return dayOfMonth == habit.selectedDayOfMonth
        case .custom:
            let dayOfMonth = calendar.component(.day, from: targetDate)
            return habit.customDays.contains(dayOfMonth)
        }
    }
}

// MARK: - Habit Row Component
struct HabitRow: View {
    let habit: HabitModel
    @Binding var quickAddState: QuickAddState
    let onDelete: () -> Void
    @EnvironmentObject var dataManager: DataManager
    @State private var showDeleteConfirm = false
    @State private var todayInstance: HabitInstanceModel?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.md) {
                // Habit icon
                Image(systemName: "repeat")
                    .font(.system(size: AppDimensions.smallIcon))
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 32, height: 32)
                    .background(AppColors.primary.opacity(0.1), in: Circle())
                
                // Habit info
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(habit.name)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.primaryText)
                    
                    HStack(spacing: AppSpacing.sm) {
                        // Frequency
                        Text(habit.frequency.rawValue)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.secondaryText)
                        
                        // Time
                        Label(timeString, systemImage: "clock")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.tertiaryText)
                    }
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: AppSpacing.sm) {
                    // Today's status
                    if let instance = todayInstance {
                        Image(systemName: instance.isCompleted ? "checkmark.circle.fill" : instance.isSkipped ? "arrow.right.circle.fill" : "circle")
                            .font(.system(size: AppDimensions.smallIcon))
                            .foregroundStyle(instance.isCompleted ? .green : instance.isSkipped ? .orange : AppColors.tertiaryText)
                    }
                    
                    // Edit button
                    Button(action: {
                        quickAddState = .habitForm(editingHabit: habit)
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: AppDimensions.smallIcon))
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    .pressableStyle()
                    
                    // Delete button
                    Button(action: { showDeleteConfirm = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: AppDimensions.smallIcon))
                            .foregroundStyle(.red.opacity(0.7))
                    }
                    .pressableStyle()
                }
            }
            .padding(AppSpacing.lg)
            
            // Progress bar
            if let completionRate = getCompletionRate() {
                VStack(spacing: 0) {
                    Divider()
                        .background(AppColors.secondaryText.opacity(0.2))
                    
                    HStack {
                        Text("\(Int(completionRate * 100))% this week")
                            .font(AppTypography.caption2)
                            .foregroundStyle(AppColors.tertiaryText)
                        
                        Spacer()
                        
                        ProgressBar(value: completionRate)
                            .frame(width: 100, height: 4)
                    }
                    .padding(AppSpacing.md)
                }
            }
        }
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                .stroke(AppColors.primary.opacity(0.3), lineWidth: 2)
        )
        .onAppear {
            todayInstance = dataManager.getHabitInstance(for: habit.id, on: Date())
        }
        .confirmationDialog(
            "Delete Habit?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will also delete all habit history.")
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: habit.remindAt)
    }
    
    private func getCompletionRate() -> Double? {
        let calendar = Calendar.current
        let endOfWeek = Date()
        guard let startOfWeek = calendar.date(byAdding: .day, value: -7, to: endOfWeek) else { return nil }
        
        let weekInstances = dataManager.habitInstances.filter { instance in
            instance.habitId == habit.id &&
            instance.scheduledDate >= startOfWeek &&
            instance.scheduledDate <= endOfWeek
        }
        
        let completedCount = weekInstances.filter { $0.isCompleted }.count
        let totalCount = max(weekInstances.count, 1)
        
        return Double(completedCount) / Double(totalCount)
    }
}

// MARK: - Calendar Grid Component
struct CalendarGrid: View {
    @Binding var selectedDate: Date
    let habits: [HabitModel]
    let habitInstances: [HabitInstanceModel]
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // Weekday headers
            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(AppTypography.caption2)
                        .foregroundStyle(AppColors.tertiaryText)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar days
            LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
                ForEach(calendarDays, id: \.self) { date in
                    if let date = date {
                        CalendarDay(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            completionCount: getCompletionCount(for: date),
                            totalCount: getTotalCount(for: date),
                            onTap: { selectedDate = date }
                        )
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
    }
    
    private var calendarDays: [Date?] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let numberOfDays = range.count
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth) - 1
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func getCompletionCount(for date: Date) -> Int {
        let calendar = Calendar.current
        return habitInstances.filter { instance in
            calendar.isDate(instance.scheduledDate, inSameDayAs: date) && instance.isCompleted
        }.count
    }
    
    private func getTotalCount(for date: Date) -> Int {
        habits.filter { habit in
            shouldHabitOccurOn(habit: habit, date: date)
        }.count
    }
    
    private func shouldHabitOccurOn(habit: HabitModel, date: Date) -> Bool {
        // Same logic as in HabitsView
        let calendar = Calendar.current
        let habitStartDate = calendar.startOfDay(for: habit.remindAt)
        let targetDate = calendar.startOfDay(for: date)
        
        guard targetDate >= habitStartDate else { return false }
        
        switch habit.frequency {
        case .noRepetition:
            return calendar.isDate(targetDate, inSameDayAs: habitStartDate)
        case .daily:
            let daysDifference = calendar.dateComponents([.day], from: habitStartDate, to: targetDate).day ?? 0
            return daysDifference % habit.dailyInterval == 0
        case .weekly:
            let weekday = calendar.component(.weekday, from: targetDate)
            let adjustedWeekday = weekday == 1 ? 7 : weekday - 1
            return habit.selectedWeekdays.contains(adjustedWeekday)
        case .monthly:
            let dayOfMonth = calendar.component(.day, from: targetDate)
            return dayOfMonth == habit.selectedDayOfMonth
        case .custom:
            let dayOfMonth = calendar.component(.day, from: targetDate)
            return habit.customDays.contains(dayOfMonth)
        }
    }
}

// MARK: - Calendar Day Component
struct CalendarDay: View {
    let date: Date
    let isSelected: Bool
    let completionCount: Int
    let totalCount: Int
    let onTap: () -> Void
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var completionPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completionCount) / Double(totalCount)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(AppTypography.caption)
                    .foregroundStyle(isToday ? .white : AppColors.primaryText)
                
                if totalCount > 0 {
                    Circle()
                        .fill(completionColor)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.sm)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSpacing.sm)
                            .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
                    )
            )
        }
        .pressableStyle()
    }
    
    private var backgroundColor: Color {
        if isToday {
            return AppColors.primary
        } else if isSelected {
            return AppColors.primary.opacity(0.1)
        } else {
            return AppColors.cardBackground
        }
    }
    
    private var borderColor: Color {
        AppColors.primary
    }
    
    private var completionColor: Color {
        if completionPercentage == 1 {
            return .green
        } else if completionPercentage > 0 {
            return .orange
        } else {
            return AppColors.tertiaryText
        }
    }
}

// MARK: - Progress Bar Component
struct ProgressBar: View {
    let value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppColors.secondaryText.opacity(0.2))
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppColors.primary)
                    .frame(width: geometry.size.width * value)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var quickAddState: QuickAddState = .hidden
    
    HabitsView(quickAddState: $quickAddState)
        .environmentObject(DataManager.shared)
}