//
//  ItemsListView.swift
//  meSync
//
//  Componente reutilizable para mostrar lista de ítems del día
//

import SwiftUI

// MARK: - Protocol for common item behavior
@MainActor
protocol ItemProtocol {
    var id: UUID { get }
    var name: String { get }
    var itemDescription: String { get }
    var scheduledTime: Date { get }
    var isCompleted: Bool { get set }
    var isSkipped: Bool { get set }
    var actionTimestamp: Date? { get }
}

// MARK: - Dynamic Habit Instance
@MainActor
class HabitInstance: ItemProtocol, ObservableObject {
    let id: UUID
    let name: String
    let itemDescription: String
    let scheduledTime: Date
    @Published var isCompleted: Bool = false
    @Published var isSkipped: Bool = false
    @Published var completedAt: Date?
    @Published var skippedAt: Date?
    
    // Reference to original habit for editing
    let originalHabit: HabitModel
    let instanceDate: Date
    let instanceKey: String  // Unique key for state tracking
    
    // Computed property for protocol
    var actionTimestamp: Date? {
        return completedAt ?? skippedAt
    }
    
    init(from habit: HabitModel, for date: Date, instance: HabitInstanceModel? = nil) {
        self.originalHabit = habit
        self.instanceDate = date
        
        // Create unique key for this instance
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.instanceKey = "\(habit.id.uuidString)_\(formatter.string(from: date))"
        
        // Create a consistent UUID based on the instance key
        let namespace = UUID(uuidString: "12345678-1234-1234-1234-123456789012")!
        self.id = UUID(namespace: namespace, name: self.instanceKey)
        
        self.name = habit.name
        self.itemDescription = habit.habitDescription
        
        // Set scheduled time to the habit's remind time on the specific date
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: habit.remindAt)
        self.scheduledTime = calendar.date(
            bySettingHour: timeComponents.hour ?? 0,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: date
        ) ?? date
        
        // Set completion state from instance if provided
        self.isCompleted = instance?.isCompleted ?? false
        self.isSkipped = instance?.isSkipped ?? false
        self.completedAt = instance?.completedAt
        self.skippedAt = instance?.skippedAt
    }
}

// Extension to create UUID from namespace and name (similar to UUID v5)
extension UUID {
    init(namespace: UUID, name: String) {
        // Create a deterministic UUID using a simpler approach
        let combined = "\(namespace.uuidString)-\(name)"
        let hash = combined.hash
        
        // Convert hash to UUID format string
        let uuidString = String(format: "%08x-%04x-%04x-%04x-%012x",
                               UInt32(truncatingIfNeeded: hash),
                               UInt16(truncatingIfNeeded: hash >> 32) | 0x4000, // Version 4
                               UInt16(truncatingIfNeeded: hash >> 48) | 0x8000, // Variant
                               UInt16.random(in: 0...UInt16.max),
                               UInt64(truncatingIfNeeded: hash))
        
        self = UUID(uuidString: uuidString) ?? UUID()
    }
}

// MARK: - Dynamic Medication Instance
@MainActor
class MedicationInstance: ItemProtocol, ObservableObject {
    let id: UUID
    let name: String
    let itemDescription: String
    let scheduledTime: Date
    @Published var isCompleted: Bool = false
    @Published var isSkipped: Bool = false
    @Published var completedAt: Date?
    @Published var skippedAt: Date?
    
    // Reference to original medication for editing
    let originalMedication: MedicationModel
    let instanceDate: Date
    let instanceKey: String  // Unique key for state tracking
    let doseNumber: Int  // Which dose of the day this is
    
    // Computed property for protocol
    var actionTimestamp: Date? {
        return completedAt ?? skippedAt
    }
    
    init(from medication: MedicationModel, for date: Date, doseNumber: Int, instance: MedicationInstanceModel? = nil) {
        self.originalMedication = medication
        self.instanceDate = date
        self.doseNumber = doseNumber
        
        // Create unique key for this instance
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.instanceKey = "\(medication.id.uuidString)_\(formatter.string(from: date))_dose\(doseNumber)"
        
        // Create a consistent UUID based on the instance key
        let namespace = UUID(uuidString: "12345678-1234-1234-1234-123456789012")!
        self.id = UUID(namespace: namespace, name: self.instanceKey)
        
        self.name = medication.name
        self.itemDescription = medication.medicationDescription
        
        // Set scheduled time based on the reminder time
        if doseNumber - 1 < medication.reminderTimes.count {
            let reminderTime = medication.reminderTimes[doseNumber - 1]
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
            self.scheduledTime = calendar.date(
                bySettingHour: timeComponents.hour ?? 0,
                minute: timeComponents.minute ?? 0,
                second: 0,
                of: date
            ) ?? date
        } else {
            self.scheduledTime = date
        }
        
        // Load state from instance if provided
        self.isCompleted = instance?.isCompleted ?? false
        self.isSkipped = instance?.isSkipped ?? false
        self.completedAt = instance?.completedAt
        self.skippedAt = instance?.skippedAt
    }
}

// MARK: - Extensions to conform to protocol
extension TaskModel: ItemProtocol {
    var itemDescription: String { taskDescription }
    var scheduledTime: Date { dueDate }
    var actionTimestamp: Date? { completedAt ?? skippedAt }
}

extension MedicationModel: ItemProtocol {
    var itemDescription: String {
        let desc = medicationDescription.isEmpty ? instructions : medicationDescription
        return desc.isEmpty ? "Take \(timesPerDay) time\(timesPerDay == 1 ? "" : "s") daily" : desc
    }
    var scheduledTime: Date { reminderTimes.first ?? Date() }
    var actionTimestamp: Date? { nil }
    var isCompleted: Bool { 
        get { false }
        set { }
    }
    var isSkipped: Bool { 
        get { false }
        set { }
    }
}

// MARK: - Items List View
struct ItemsListView: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var quickAddState: QuickAddState
    
    // Force refresh trigger
    @State private var refreshTrigger = 0
    
    // MARK: - 3-Day Window Configuration
    private var dateRange: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<3).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: today)
        }
    }
    
    var body: some View {
        LazyVStack(spacing: AppSpacing.md) {
            if allItems.isEmpty {
                emptyStateView
            } else {
                // Active Items
                ForEach(activeItems, id: \.id) { item in
                    ItemCard(
                        item: item,
                        quickAddState: $quickAddState,
                        refreshTrigger: $refreshTrigger
                    )
                    .id("\(item.id)-\(refreshTrigger)")
                }
                
                // Divider (only show if there are completed or skipped items)
                if !completedAndSkippedItems.isEmpty {
                    VStack(spacing: AppSpacing.sm) {
                        Divider()
                            .background(AppColors.secondaryText.opacity(0.4))
                            .frame(height: 1)
                        
                        Text("Completed & Skipped")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.tertiaryText)
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }
                    .padding(.vertical, AppSpacing.lg)
                }
                
                // Completed and Skipped Items
                ForEach(completedAndSkippedItems, id: \.id) { item in
                    ItemCard(
                        item: item,
                        quickAddState: $quickAddState,
                        refreshTrigger: $refreshTrigger
                    )
                    .id("\(item.id)-\(refreshTrigger)")
                }
            }
        }
        .standardHorizontalPadding()
        .id("itemsList-\(refreshTrigger)")  // Force refresh when trigger changes
    }
    
    // MARK: - Dynamic Habit Generation
    private func generateHabitInstances() -> [HabitInstance] {
        var instances: [HabitInstance] = []
        
        for habit in dataManager.habits {
            for date in dateRange {
                if shouldHabitOccurOn(habit: habit, date: date) {
                    let existingInstance = dataManager.getHabitInstance(for: habit.id, on: date)
                    let instance = HabitInstance(from: habit, for: date, instance: existingInstance)
                    instances.append(instance)
                }
            }
        }
        
        return instances
    }
    
    // MARK: - Dynamic Medication Generation
    private func generateMedicationInstances() -> [MedicationInstance] {
        var instances: [MedicationInstance] = []
        
        for medication in dataManager.medications {
            for date in dateRange {
                // Generate instances for each dose time
                for doseNumber in 1...medication.timesPerDay {
                    let existingInstance = dataManager.getMedicationInstance(
                        for: medication.id,
                        on: date,
                        doseNumber: doseNumber
                    )
                    let instance = MedicationInstance(
                        from: medication,
                        for: date,
                        doseNumber: doseNumber,
                        instance: existingInstance
                    )
                    instances.append(instance)
                }
            }
        }
        
        return instances
    }
    
    // Computed properties for combined items organization
    private var allItems: [any ItemProtocol] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let threeDaysFromNow = calendar.date(byAdding: .day, value: 3, to: today) ?? today
        
        // Filter tasks to 3-day window
        let filteredTasks: [any ItemProtocol] = dataManager.tasks.filter { task in
            let taskDate = calendar.startOfDay(for: task.dueDate)
            return taskDate >= today && taskDate < threeDaysFromNow
        }
        
        // Generate habit instances for 3-day window
        let habitInstances: [any ItemProtocol] = generateHabitInstances()
        
        // Generate medication instances for 3-day window
        let medicationInstances: [any ItemProtocol] = generateMedicationInstances()
        
        return (filteredTasks + habitInstances + medicationInstances).sorted { $0.scheduledTime < $1.scheduledTime }
    }
    
    private var activeItems: [any ItemProtocol] {
        allItems.filter { !$0.isCompleted && !$0.isSkipped }
    }
    
    private var completedAndSkippedItems: [any ItemProtocol] {
        let calendar = Calendar.current
        let now = Date()
        let cutoffHour = 2 // 2 AM
        
        return allItems.filter { item in
            guard item.isCompleted || item.isSkipped else { return false }
            
            // Get the timestamp when the item was marked as completed/skipped
            guard let actionTimestamp = item.actionTimestamp else { return true }
            
            // Calculate the cutoff time (2 AM the day after the action)
            let dayAfterAction = calendar.date(byAdding: .day, value: 1, to: actionTimestamp) ?? actionTimestamp
            let cutoffTime = calendar.date(bySettingHour: cutoffHour, minute: 0, second: 0, of: dayAfterAction) ?? dayAfterAction
            
            // Hide the item if current time is past the cutoff time
            return now < cutoffTime
        }
        .sorted { item1, item2 in
            // Completed items first, then skipped items
            if item1.isCompleted != item2.isCompleted {
                return item1.isCompleted
            }
            return item1.scheduledTime < item2.scheduledTime
        }
    }
    
    private func shouldHabitOccurOn(habit: HabitModel, date: Date) -> Bool {
        let calendar = Calendar.current
        let habitStartDate = calendar.startOfDay(for: habit.remindAt)
        let targetDate = calendar.startOfDay(for: date)
        
        // Don't show habits before their start date
        guard targetDate >= habitStartDate else { return false }
        
        switch habit.frequency {
        case .noRepetition:
            return calendar.isDate(targetDate, inSameDayAs: habitStartDate)
            
        case .daily:
            let daysDifference = calendar.dateComponents([.day], from: habitStartDate, to: targetDate).day ?? 0
            return daysDifference % habit.dailyInterval == 0
            
        case .weekly:
            let weekday = calendar.component(.weekday, from: targetDate)
            let adjustedWeekday = weekday == 1 ? 7 : weekday - 1  // Convert to Monday=1 format
            
            if habit.selectedWeekdays.contains(adjustedWeekday) {
                let weeksDifference = calendar.dateComponents([.weekOfYear], from: habitStartDate, to: targetDate).weekOfYear ?? 0
                return weeksDifference % habit.weeklyInterval == 0
            }
            return false
            
        case .monthly:
            let dayOfMonth = calendar.component(.day, from: targetDate)
            if dayOfMonth == habit.selectedDayOfMonth {
                let monthsDifference = calendar.dateComponents([.month], from: habitStartDate, to: targetDate).month ?? 0
                return monthsDifference % habit.monthlyInterval == 0
            }
            return false
            
        case .custom:
            let dayOfMonth = calendar.component(.day, from: targetDate)
            return habit.customDays.contains(dayOfMonth)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "plus.circle")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.secondaryText)
            
            Text("No items scheduled for the next 3 days")
                .subtitleStyle()
                .multilineTextAlignment(.center)
            
            Text("Tap Quick Add to create your first task or habit")
                .captionStyle()
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, AppSpacing.xxxl)
    }
    
}

// MARK: - Universal Item Card
struct ItemCard: View {
    let item: any ItemProtocol
    @Binding var quickAddState: QuickAddState
    @Binding var refreshTrigger: Int
    @EnvironmentObject private var dataManager: DataManager
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            HStack(spacing: AppSpacing.md) {
                // Left side actions based on task state
                leftSideActions
                
                // Main content
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack {
                        Text(item.name)
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(textColor)
                            .lineLimit(2)
                        
                        // Item type indicator
                        itemTypeIndicator
                        
                        // Description indicator
                        if hasDescription {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(AppColors.tertiaryText)
                                .animation(.easeInOut(duration: 0.2), value: isExpanded)
                        }
                    }
                    
                    HStack(spacing: AppSpacing.xs) {
                        Text("\(dateString), \(timeString)")
                            .font(AppTypography.caption)
                            .foregroundStyle(secondaryTextColor)
                        
                        priorityIndicator
                    }
                }
                
                Spacer()
                
                // Right side actions based on task state
                rightSideActions
            }
            .padding(AppSpacing.lg)
            
            // Expandable description section
            if isExpanded && hasDescription {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Divider()
                        .background(AppColors.secondaryText.opacity(0.3))
                    
                    Text(item.itemDescription)
                        .font(AppTypography.body)
                        .foregroundStyle(textColor.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    )
                )
            }
        }
        .background(
            cardBackground,
            in: RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                .stroke(priorityBorderColor, lineWidth: 2)
        )
        .onLongPressGesture(minimumDuration: 0.5) {
            if hasDescription {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }
        }
        .onTapGesture {
            if isExpanded {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded = false
                }
            }
        }
    }
    
    // MARK: - Left Side Actions
    @ViewBuilder
    private var leftSideActions: some View {
        if item.isCompleted || item.isSkipped {
            // No left actions for completed or skipped items
            EmptyView()
        } else {
            // Edit button for active items only
            actionButton(systemImage: "pencil", action: editAction)
        }
    }
    
    // MARK: - Right Side Actions
    @ViewBuilder
    private var rightSideActions: some View {
        if item.isCompleted {
            // Only checkmark for completed items (green to show active state)
            actionButton(
                systemImage: "checkmark.circle.fill",
                color: .green,
                action: toggleCompleteAction
            )
        } else if item.isSkipped {
            // Only skip button (orange to show active state) for skipped items
            actionButton(
                systemImage: "arrow.right.circle.fill",
                color: .orange,
                action: toggleSkipAction
            )
        } else {
            // All three buttons for active items
            HStack(spacing: AppSpacing.sm) {
                actionButton(
                    systemImage: "arrow.right.circle",
                    action: toggleSkipAction
                )
                actionButton(
                    systemImage: "checkmark.circle",
                    action: toggleCompleteAction
                )
            }
        }
    }
    
    // MARK: - Item Type Indicator
    @ViewBuilder
    private var itemTypeIndicator: some View {
        if item is TaskModel {
            Image(systemName: "checkmark.square")
                .font(.caption2)
                .foregroundStyle(AppColors.primary)
        } else if item is HabitInstance {
            Image(systemName: "repeat")
                .font(.caption2)
                .foregroundStyle(AppColors.primary)
        } else if item is MedicationInstance {
            Image(systemName: "pills.fill")
                .font(.caption2)
                .foregroundStyle(Color.blue)
        }
    }
    
    // MARK: - Priority Indicator
    @ViewBuilder
    private var priorityIndicator: some View {
        if let taskItem = item as? TaskModel {
            HStack(spacing: AppSpacing.xs) {
                Circle()
                    .fill(priorityColor)
                    .frame(width: 6, height: 6)
                
                Text(taskItem.priority.rawValue)
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColors.tertiaryText)
            }
        } else if let habitInstance = item as? HabitInstance {
            // For habit instances, show frequency info from original habit
            Text(habitInstance.originalHabit.frequency.rawValue)
                .font(AppTypography.caption2)
                .foregroundStyle(AppColors.tertiaryText)
        } else if let medicationInstance = item as? MedicationInstance {
            // For medication instances, show dose number
            Text("Dose \(medicationInstance.doseNumber)")
                .font(AppTypography.caption2)
                .foregroundStyle(AppColors.tertiaryText)
        }
    }
    
    // MARK: - Action Button
    private func actionButton(
        systemImage: String,
        color: Color = AppColors.secondaryText,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: AppDimensions.mediumIcon))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(AppColors.background, in: Circle())
        }
        .pressableStyle()
    }
    
    // MARK: - Computed Properties
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: item.scheduledTime)
    }
    
    private var dateString: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let itemDate = calendar.startOfDay(for: item.scheduledTime)
        
        if calendar.isDate(itemDate, inSameDayAs: today) {
            return "Today"
        } else if calendar.isDate(itemDate, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: today) ?? today) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: item.scheduledTime)
        }
    }
    
    private var hasDescription: Bool {
        !item.itemDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var priorityColor: Color {
        if let taskItem = item as? TaskModel {
            switch taskItem.priority {
            case .low:
                return .green
            case .medium:
                return .orange
            case .high:
                return .red
            case .urgent:
                return .purple
            }
        } else {
            return AppColors.primary  // Default color for habits
        }
    }
    
    private var priorityBorderColor: Color {
        priorityColor.opacity(0.3)
    }
    
    // MARK: - State-based Styling
    private var cardBackground: Color {
        if item.isCompleted {
            return Color.gray.opacity(0.2)  // More visible gray for completed
        } else if item.isSkipped {
            return Color.orange.opacity(0.15)  // More visible orange for skipped
        } else {
            return AppColors.cardBackground  // Normal for active
        }
    }
    
    private var textColor: Color {
        if item.isCompleted {
            return AppColors.primaryText.opacity(0.7)
        } else {
            return AppColors.primaryText
        }
    }
    
    private var secondaryTextColor: Color {
        if item.isCompleted {
            return AppColors.secondaryText.opacity(0.7)
        } else {
            return AppColors.secondaryText
        }
    }
    
    // MARK: - Actions
    private func editAction() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let taskItem = item as? TaskModel {
                quickAddState = .taskForm(editingTask: taskItem)
            } else if let habitInstance = item as? HabitInstance {
                // Edit the original habit, not the instance
                quickAddState = .habitForm(editingHabit: habitInstance.originalHabit)
            } else if let medicationInstance = item as? MedicationInstance {
                // Edit the original medication, not the instance
                quickAddState = .medicationForm(editingMedication: medicationInstance.originalMedication)
            }
        }
    }
    
    private func toggleSkipAction() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if var taskItem = item as? TaskModel {
                taskItem.isSkipped.toggle()
                taskItem.isCompleted = false  // Ensure it's not completed when skipped
                taskItem.skippedAt = taskItem.isSkipped ? Date() : nil
                taskItem.completedAt = nil
                taskItem.updatedAt = Date()
                dataManager.saveTask(taskItem)
                
                // Force refresh for tasks
                refreshTrigger += 1
            } else if let habitInstance = item as? HabitInstance {
                // Update in-memory state
                habitInstance.isCompleted = false
                habitInstance.isSkipped = !habitInstance.isSkipped
                habitInstance.completedAt = nil
                habitInstance.skippedAt = habitInstance.isSkipped ? Date() : nil
                
                // Update persistent state
                if habitInstance.isSkipped {
                    dataManager.skipHabit(for: habitInstance.originalHabit.id, on: habitInstance.instanceDate)
                } else {
                    // Remove the instance if unmarking skip
                    if let existingInstance = dataManager.getHabitInstance(for: habitInstance.originalHabit.id, on: habitInstance.instanceDate) {
                        dataManager.habitInstances.removeAll { $0.id == existingInstance.id }
                        dataManager.saveData(dataManager.habitInstances, to: "habit_instances")
                    }
                }
                
                // Force refresh of the view
                refreshTrigger += 1
            } else if let medicationInstance = item as? MedicationInstance {
                // Update in-memory state
                medicationInstance.isCompleted = false
                medicationInstance.isSkipped = !medicationInstance.isSkipped
                medicationInstance.completedAt = nil
                medicationInstance.skippedAt = medicationInstance.isSkipped ? Date() : nil
                
                // Update persistent state
                if medicationInstance.isSkipped {
                    dataManager.skipMedication(
                        for: medicationInstance.originalMedication.id,
                        on: medicationInstance.instanceDate,
                        doseNumber: medicationInstance.doseNumber
                    )
                } else {
                    // Remove the instance if unmarking skip
                    if let existingInstance = dataManager.getMedicationInstance(
                        for: medicationInstance.originalMedication.id,
                        on: medicationInstance.instanceDate,
                        doseNumber: medicationInstance.doseNumber
                    ) {
                        dataManager.medicationInstances.removeAll { $0.id == existingInstance.id }
                        dataManager.saveData(dataManager.medicationInstances, to: "medication_instances")
                    }
                }
                
                // Force refresh of the view
                refreshTrigger += 1
            }
        }
    }
    
    private func toggleCompleteAction() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if var taskItem = item as? TaskModel {
                taskItem.isCompleted.toggle()
                taskItem.isSkipped = false  // Ensure it's not skipped when completed
                taskItem.completedAt = taskItem.isCompleted ? Date() : nil
                taskItem.skippedAt = nil
                taskItem.updatedAt = Date()
                dataManager.saveTask(taskItem)
                
                // Force refresh for tasks
                refreshTrigger += 1
            } else if let habitInstance = item as? HabitInstance {
                // Update in-memory state
                habitInstance.isCompleted = !habitInstance.isCompleted
                habitInstance.isSkipped = false
                habitInstance.completedAt = habitInstance.isCompleted ? Date() : nil
                habitInstance.skippedAt = nil
                
                // Update persistent state
                dataManager.toggleHabitCompletion(for: habitInstance.originalHabit.id, on: habitInstance.instanceDate)
                
                // Force refresh of the view
                refreshTrigger += 1
            } else if let medicationInstance = item as? MedicationInstance {
                // Update in-memory state
                medicationInstance.isCompleted = !medicationInstance.isCompleted
                medicationInstance.isSkipped = false
                medicationInstance.completedAt = medicationInstance.isCompleted ? Date() : nil
                medicationInstance.skippedAt = nil
                
                // Update persistent state
                dataManager.toggleMedicationCompletion(
                    for: medicationInstance.originalMedication.id,
                    on: medicationInstance.instanceDate,
                    doseNumber: medicationInstance.doseNumber
                )
                
                // Force refresh of the view
                refreshTrigger += 1
            }
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var quickAddState: QuickAddState = .hidden
    
    ItemsListView(quickAddState: $quickAddState)
        .environmentObject(DataManager.shared)
}