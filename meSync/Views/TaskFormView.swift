//
//  TaskFormViewMigrated.swift
//  meSync
//
//  Formulario reutilizable para crear y editar tareas (versión migrada)
//

import SwiftUI

struct TaskFormView: View {
    @Binding var quickAddState: QuickAddState
    @EnvironmentObject var dataManager: DataManager
    
    // Form data
    @State private var name: String = ""
    @State private var taskDescription: String = ""
    @State private var selectedPriority: TaskPriority = .medium
    @State private var dueDate: Date = Date()
    
    // UI State
    @FocusState private var isNameFocused: Bool
    @FocusState private var isDescriptionFocused: Bool
    
    // Editing task reference
    private let editingTask: TaskModel?
    
    // Computed properties
    private var isEditing: Bool {
        editingTask != nil
    }
    
    private var formTitle: String {
        isEditing ? "Editing Task" : "Creating Task"
    }
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Initializer
    init(quickAddState: Binding<QuickAddState>) {
        self._quickAddState = quickAddState
        
        // Extract editing task if available
        if case .taskForm(let task) = quickAddState.wrappedValue {
            self.editingTask = task
            self._name = State(initialValue: task?.name ?? "")
            self._taskDescription = State(initialValue: task?.taskDescription ?? "")
            self._selectedPriority = State(initialValue: task?.priority ?? .medium)
            self._dueDate = State(initialValue: task?.dueDate ?? Date())
        } else {
            self.editingTask = nil
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Form Content
            ScrollView {
                VStack(spacing: AppSpacing.xs) {
                    // Form Title
                    Text(isEditing ? "Edit Task" : "Create New Task")
                        .sectionTitleStyle()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, AppSpacing.sm)
                    
                    // Name Field
                    nameField
                    
                    // Description Field
                    descriptionField
                    
                    // Due Date
                    dueDateField
                    
                    // Priority Selection
                    prioritySection
                }
                .padding(.top, AppSpacing.md)
            }
            
            // Action Buttons
            actionButtons
        }
        .formContainerStyle()
        .onAppear {
            // Focus on name field when form appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isNameFocused = true
            }
        }
    }
    
    // MARK: - Form Fields
    private var nameField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Name")
                .formLabelStyle()
                .foregroundStyle(AppColors.primaryText)
            
            TextField("Enter task name", text: $name)
                .focused($isNameFocused)
                .formInputStyle()
        }
        .formSectionStyle()
    }
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Description")
                .formLabelStyle()
                .foregroundStyle(AppColors.primaryText)
            
            DynamicHeightTextEditor(text: $taskDescription, placeholder: "Add task description...")
        }
        .formSectionStyle()
    }
    
    private var dueDateField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Due Date")
                .formLabelStyle()
                .foregroundStyle(AppColors.primaryText)
            
            VStack(spacing: AppSpacing.sm) {
                CompactDatePicker(
                    title: "Date",
                    date: $dueDate,
                    components: .date
                )
                
                CompactTimePicker(
                    title: "Time",
                    time: $dueDate
                )
            }
        }
        .formSectionStyle()
    }
    
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Priority")
                .formLabelStyle()
                .foregroundStyle(AppColors.primaryText)
            
            VStack(spacing: AppSpacing.xs) {
                ForEach(TaskPriority.allCases, id: \.self) { priority in
                    priorityButton(for: priority)
                }
            }
        }
        .formSectionStyle()
    }
    
    private func priorityButton(for priority: TaskPriority) -> some View {
        Button(action: {
            selectedPriority = priority
        }) {
            HStack {
                Image(systemName: selectedPriority == priority ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedPriority == priority ? AppColors.primary : AppColors.tertiaryText)
                
                Text(priority.rawValue)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.primaryText)
                
                Spacer()
                
                Text("●")
                    .foregroundStyle(priorityColor(for: priority))
                    .font(AppTypography.caption)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                .fill(selectedPriority == priority ? AppColors.primary.opacity(0.1) : Color.clear)
        )
    }
    
    private func priorityColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .low: return AppColors.taskPriorityLow
        case .medium: return AppColors.taskPriorityMedium
        case .high: return AppColors.taskPriorityHigh
        case .urgent: return AppColors.taskPriorityUrgent
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: AppSpacing.sm) {
            // Cancel and Save buttons
            HStack(spacing: AppSpacing.md) {
                Button("Cancel") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        quickAddState.cancel()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                
                Button("Save") {
                    saveTask()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(!canSave)
            }
            
            // Delete button (only when editing)
            if isEditing {
                Button("Delete Task", role: .destructive) {
                    deleteTask()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
        }
        .standardHorizontalPadding()
        .padding(.vertical, AppSpacing.lg)
        .background(AppColors.cardBackground)
        .overlay(
            Rectangle()
                .frame(height: AppDimensions.dividerHeight)
                .foregroundStyle(AppColors.secondaryText.opacity(0.2)),
            alignment: .top
        )
    }
    
    // MARK: - Actions
    private func saveTask() {
        guard canSave else { return }
        
        let task = TaskModel(
            id: editingTask?.id ?? UUID(),
            name: name,
            taskDescription: taskDescription,
            priority: selectedPriority,
            dueDate: dueDate,
            isCompleted: editingTask?.isCompleted ?? false,
            isSkipped: editingTask?.isSkipped ?? false,
            completedAt: editingTask?.completedAt,
            skippedAt: editingTask?.skippedAt
        )
        
        dataManager.saveTask(task)
        
        // Close form
        withAnimation(.easeInOut(duration: 0.3)) {
            quickAddState.hide()
        }
    }
    
    private func deleteTask() {
        guard let task = editingTask else { return }
        
        dataManager.deleteTask(task)
        
        // Close form
        withAnimation(.easeInOut(duration: 0.3)) {
            quickAddState.hide()
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var quickAddState: QuickAddState = .taskForm()
    
    TaskFormView(quickAddState: $quickAddState)
        .environmentObject(DataManager.shared)
}