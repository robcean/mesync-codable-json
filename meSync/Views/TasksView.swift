//
//  TasksView.swift
//  meSync
//
//  Vista dedicada para gestionar todas las tareas
//

import SwiftUI

struct TasksView: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var quickAddState: QuickAddState
    
    // Filter and sort states
    @State private var selectedFilter: TaskFilter = .all
    @State private var sortBy: TaskSort = .dueDate
    @State private var searchText = ""
    @State private var showCompleted = false
    
    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case upcoming = "Upcoming"
        case overdue = "Overdue"
    }
    
    enum TaskSort: String, CaseIterable {
        case dueDate = "Due Date"
        case priority = "Priority"
        case name = "Name"
        case created = "Created"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            // Content
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Stats cards
                    statsSection
                    
                    // Filter chips
                    filterSection
                    
                    // Search bar
                    searchBar
                    
                    // Sort options
                    sortSection
                    
                    // Tasks list
                    tasksList
                }
                .padding(.top, AppSpacing.md)
            }
        }
        .mainContainerStyle()
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Text("Tasks")
                .sectionTitleStyle()
            
            Spacer()
            
            // Add new task button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    quickAddState = .taskForm(editingTask: nil)
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
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: AppSpacing.md) {
            StatCard(
                title: "Total",
                value: "\(dataManager.tasks.count)",
                icon: "list.bullet",
                color: .blue
            )
            
            StatCard(
                title: "Pending",
                value: "\(pendingTasks.count)",
                icon: "clock",
                color: .orange
            )
            
            StatCard(
                title: "Completed",
                value: "\(completedTasks.count)",
                icon: "checkmark.circle",
                color: .green
            )
        }
        .standardHorizontalPadding()
    }
    
    // MARK: - Filter Section
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
                
                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, AppSpacing.xs)
                
                // Show completed toggle
                FilterChip(
                    title: "Show Completed",
                    isSelected: showCompleted,
                    action: { showCompleted.toggle() }
                )
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.tertiaryText)
            
            TextField("Search tasks...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
        .standardHorizontalPadding()
    }
    
    // MARK: - Sort Section
    private var sortSection: some View {
        HStack {
            Text("Sort by:")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.secondaryText)
            
            Menu {
                ForEach(TaskSort.allCases, id: \.self) { sort in
                    Button(action: { sortBy = sort }) {
                        HStack {
                            Text(sort.rawValue)
                            if sortBy == sort {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Text(sortBy.rawValue)
                        .font(AppTypography.caption)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(AppColors.primary)
            }
            
            Spacer()
        }
        .standardHorizontalPadding()
    }
    
    // MARK: - Tasks List
    private var tasksList: some View {
        LazyVStack(spacing: AppSpacing.md) {
            if filteredTasks.isEmpty {
                emptyStateView
            } else {
                ForEach(filteredTasks) { task in
                    TaskRow(
                        task: task,
                        quickAddState: $quickAddState,
                        onToggleComplete: {
                            dataManager.toggleTaskCompletion(task)
                        },
                        onDelete: {
                            withAnimation {
                                dataManager.deleteTask(task)
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
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.secondaryText)
            
            Text("No tasks found")
                .subtitleStyle()
            
            Text("Try adjusting your filters or add a new task")
                .captionStyle()
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, AppSpacing.xxxl)
    }
    
    // MARK: - Computed Properties
    private var pendingTasks: [TaskModel] {
        dataManager.tasks.filter { !$0.isCompleted && !$0.isSkipped }
    }
    
    private var completedTasks: [TaskModel] {
        dataManager.tasks.filter { $0.isCompleted }
    }
    
    private var filteredTasks: [TaskModel] {
        var tasks = showCompleted ? dataManager.tasks : pendingTasks
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .today:
            let calendar = Calendar.current
            tasks = tasks.filter { calendar.isDateInToday($0.dueDate) }
        case .upcoming:
            let now = Date()
            tasks = tasks.filter { $0.dueDate > now }
        case .overdue:
            let now = Date()
            tasks = tasks.filter { $0.dueDate < now && !$0.isCompleted }
        }
        
        // Apply search
        if !searchText.isEmpty {
            tasks = tasks.filter { task in
                task.name.localizedCaseInsensitiveContains(searchText) ||
                task.taskDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply sort
        switch sortBy {
        case .dueDate:
            tasks.sort { $0.dueDate < $1.dueDate }
        case .priority:
            tasks.sort { $0.priority.sortOrder < $1.priority.sortOrder }
        case .name:
            tasks.sort { $0.name < $1.name }
        case .created:
            tasks.sort { $0.createdAt < $1.createdAt }
        }
        
        return tasks
    }
}

// MARK: - Task Row Component
struct TaskRow: View {
    let task: TaskModel
    @Binding var quickAddState: QuickAddState
    let onToggleComplete: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteConfirm = false
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Complete button
            Button(action: onToggleComplete) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: AppDimensions.smallIcon))
                    .foregroundStyle(task.isCompleted ? .green : AppColors.secondaryText)
            }
            .pressableStyle()
            
            // Task info
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(task.name)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(task.isCompleted ? AppColors.primaryText.opacity(0.6) : AppColors.primaryText)
                    .strikethrough(task.isCompleted)
                
                HStack(spacing: AppSpacing.sm) {
                    // Due date
                    Label(dueDateString, systemImage: "calendar")
                        .font(AppTypography.caption)
                        .foregroundStyle(dueDateColor)
                    
                    // Priority
                    HStack(spacing: 2) {
                        Circle()
                            .fill(priorityColor)
                            .frame(width: 6, height: 6)
                        Text(task.priority.rawValue)
                    }
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColors.tertiaryText)
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: AppSpacing.sm) {
                // Edit button
                Button(action: {
                    quickAddState = .taskForm(editingTask: task)
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
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                .stroke(priorityColor.opacity(0.3), lineWidth: 2)
        )
        .confirmationDialog(
            "Delete Task?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private var dueDateString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: task.dueDate, relativeTo: Date())
    }
    
    private var dueDateColor: Color {
        let now = Date()
        if task.isCompleted {
            return AppColors.secondaryText.opacity(0.6)
        } else if task.dueDate < now {
            return .red
        } else if Calendar.current.isDateInToday(task.dueDate) {
            return .orange
        } else {
            return AppColors.secondaryText
        }
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .urgent: return .purple
        }
    }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(isSelected ? .white : AppColors.primaryText)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    isSelected ? AppColors.primary : AppColors.cardBackground,
                    in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                )
        }
        .pressableStyle()
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: AppDimensions.smallIcon))
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColors.primaryText)
                
                Text(title)
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColors.tertiaryText)
            }
            
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Priority Extension
extension TaskPriority {
    var sortOrder: Int {
        switch self {
        case .urgent: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var quickAddState: QuickAddState = .hidden
    
    TasksView(quickAddState: $quickAddState)
        .environmentObject(DataManager.shared)
}