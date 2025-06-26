//
//  ItemsListView.swift
//  meSync
//
//  Componente reutilizable para mostrar lista de ítems del día
//

import SwiftUI

// MARK: - Protocol for common item behavior
protocol ItemProtocol {
    var id: UUID { get }
    var name: String { get }
    var itemDescription: String { get }
    var scheduledTime: Date { get }
    var isCompleted: Bool { get }
    var isSkipped: Bool { get }
}

// MARK: - Dynamic Habit Instance
class HabitInstance: ItemProtocol, ObservableObject {
    let id: UUID
    let name: String
    let itemDescription: String
    let scheduledTime: Date
    var isCompleted: Bool
    var isSkipped: Bool
    
    // Reference to original habit for editing
    let originalHabit: HabitModel
    let instanceDate: Date
    
    init(from habit: HabitModel, for date: Date, instance: HabitInstanceModel? = nil) {
        self.originalHabit = habit
        self.instanceDate = date
        
        // Create a consistent UUID for this specific instance
        let dateString = ISO8601DateFormatter().string(from: date)
        let combinedString = "\(habit.id.uuidString)_\(dateString)"
        // Use a deterministic UUID based on the string
        self.id = UUID(uuidString: combinedString.data(using: .utf8)!.base64EncodedString()) ?? UUID()
        
        self.name = habit.name
        self.itemDescription = habit.habitDescription
        self.scheduledTime = habit.remindAt
        self.isCompleted = instance?.isCompleted ?? false
        self.isSkipped = instance?.isSkipped ?? false
    }
}

// MARK: - Task Wrapper
extension TaskModel: ItemProtocol {
    var itemDescription: String { taskDescription }
    var scheduledTime: Date { dueDate }
}

// MARK: - Items List View
struct ItemsListView: View {
    @Binding var quickAddState: QuickAddState
    @EnvironmentObject var dataManager: DataManager
    @State private var currentDate = Date()
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Header
            sectionHeader
            
            // Items list
            if allItems.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: AppSpacing.md) {
                    ForEach(allItems, id: \.id) { item in
                        ItemRow(
                            item: item,
                            onToggleComplete: { toggleItemCompletion(item) },
                            onSkip: { skipItem(item) },
                            onEdit: { editItem(item) }
                        )
                    }
                }
            }
        }
        .standardHorizontalPadding()
    }
    
    // MARK: - Computed Properties
    
    private var allItems: [any ItemProtocol] {
        let calendar = Calendar.current
        let today = Date()
        
        // Get today's tasks
        let todayTasks = dataManager.tasks.filter { task in
            calendar.isDate(task.dueDate, inSameDayAs: today)
        }
        
        // Generate habit instances for habits that should appear today
        let habitInstances = dataManager.habits.compactMap { habit -> HabitInstance? in
            if shouldShowHabit(habit, on: today) {
                let instance = dataManager.getHabitInstance(for: habit.id, on: today)
                return HabitInstance(from: habit, for: today, instance: instance)
            }
            return nil
        }
        
        // Combine and sort by time
        let items: [any ItemProtocol] = todayTasks + habitInstances
        return items.sorted { $0.scheduledTime < $1.scheduledTime }
    }
    
    private func shouldShowHabit(_ habit: HabitModel, on date: Date) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
        let habitStart = calendar.startOfDay(for: habit.remindAt)
        let targetDate = calendar.startOfDay(for: date)
        
        // Don't show habits scheduled for future dates
        guard targetDate >= habitStart else { return false }
        
        switch habit.frequency {
        case .noRepetition:
            return calendar.isDate(habit.remindAt, inSameDayAs: date)
            
        case .daily:
            let daysDifference = calendar.dateComponents([.day], from: habitStart, to: targetDate).day ?? 0
            return daysDifference >= 0 && daysDifference % habit.dailyInterval == 0
            
        case .weekly:
            guard let weekday = components.weekday else { return false }
            let adjustedWeekday = weekday == 1 ? 7 : weekday - 1
            guard habit.selectedWeekdays.contains(adjustedWeekday) else { return false }
            
            let weeksDifference = calendar.dateComponents([.weekOfYear], from: habitStart, to: targetDate).weekOfYear ?? 0
            return weeksDifference >= 0 && weeksDifference % habit.weeklyInterval == 0
            
        case .monthly:
            guard let day = components.day else { return false }
            guard day == habit.selectedDayOfMonth else { return false }
            
            let monthsDifference = calendar.dateComponents([.month], from: habitStart, to: targetDate).month ?? 0
            return monthsDifference >= 0 && monthsDifference % habit.monthlyInterval == 0
            
        case .custom:
            guard let day = components.day else { return false }
            return habit.customDays.contains(day)
        }
    }
    
    // MARK: - Subviews
    
    private var sectionHeader: some View {
        HStack {
            Text("Today's Items")
                .sectionTitleStyle()
            
            Spacer()
            
            Text("\(allItems.count)")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.tertiaryText)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                        .fill(AppColors.cardBackground)
                )
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.success)
            
            Text("No items for today")
                .subtitleStyle()
                .foregroundStyle(AppColors.secondaryText)
            
            Text("Add some tasks or habits to get started")
                .captionStyle()
                .foregroundStyle(AppColors.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxxl)
    }
    
    // MARK: - Actions
    
    private func toggleItemCompletion(_ item: any ItemProtocol) {
        if let task = item as? TaskModel {
            dataManager.toggleTaskCompletion(task)
        } else if let habitInstance = item as? HabitInstance {
            dataManager.toggleHabitCompletion(for: habitInstance.originalHabit.id, on: habitInstance.instanceDate)
        }
    }
    
    private func skipItem(_ item: any ItemProtocol) {
        if let habitInstance = item as? HabitInstance {
            dataManager.skipHabit(for: habitInstance.originalHabit.id, on: habitInstance.instanceDate)
        }
        // Tasks don't have skip functionality in current implementation
    }
    
    private func editItem(_ item: any ItemProtocol) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let task = item as? TaskModel {
                quickAddState = .taskForm(editingTask: task)
            } else if let habitInstance = item as? HabitInstance {
                quickAddState = .habitForm(editingHabit: habitInstance.originalHabit)
            }
        }
    }
}

// MARK: - Item Row Component
struct ItemRow: View {
    let item: any ItemProtocol
    let onToggleComplete: () -> Void
    let onSkip: () -> Void
    let onEdit: () -> Void
    
    @State private var showingMenu = false
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Completion button
            Button(action: onToggleComplete) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: AppDimensions.mediumIcon))
                    .foregroundStyle(item.isCompleted ? AppColors.success : AppColors.tertiaryText)
            }
            .pressableStyle()
            
            // Item content
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Text(item.name)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.primaryText)
                        .strikethrough(item.isCompleted || item.isSkipped)
                    
                    Spacer()
                    
                    // Time
                    Text(timeString(from: item.scheduledTime))
                        .captionStyle()
                        .foregroundStyle(AppColors.tertiaryText)
                }
                
                if !item.itemDescription.isEmpty {
                    Text(item.itemDescription)
                        .captionStyle()
                        .foregroundStyle(AppColors.secondaryText)
                        .lineLimit(2)
                }
                
                // Priority/Type indicator
                HStack(spacing: AppSpacing.sm) {
                    if let task = item as? TaskModel {
                        TaskPriorityBadge(priority: task.priority)
                    } else if item is HabitInstance {
                        HabitTypeBadge()
                    }
                    
                    Spacer()
                    
                    if item.isSkipped {
                        Text("Skipped")
                            .font(AppTypography.caption2)
                            .foregroundStyle(AppColors.warning)
                    }
                }
            }
            
            // Menu button
            Menu {
                Button("Edit", systemImage: "pencil") {
                    onEdit()
                }
                
                if item is HabitInstance {
                    Button("Skip", systemImage: "forward.fill") {
                        onSkip()
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: AppDimensions.smallIcon))
                    .foregroundStyle(AppColors.tertiaryText)
                    .frame(width: 32, height: 32)
            }
        }
        .itemCardStyle()
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Components
struct TaskPriorityBadge: View {
    let priority: TaskPriority
    
    var body: some View {
        Text(priority.rawValue)
            .font(AppTypography.caption2)
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(priorityColor)
            )
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .urgent: return .purple
        }
    }
}

struct HabitTypeBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "repeat")
                .font(.system(size: 10))
            Text("Habit")
                .font(AppTypography.caption2)
        }
        .foregroundStyle(AppColors.primary)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(AppColors.primary.opacity(0.1))
        )
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var quickAddState: QuickAddState = .hidden
    
    ItemsListView(quickAddState: $quickAddState)
        .environmentObject(DataManager.shared)
}