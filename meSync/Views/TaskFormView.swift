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
            // Header
            formHeader
            
            // Form Content
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Name Field
                    nameField
                    
                    // Description Field
                    descriptionField
                    
                    // Due Date
                    dueDateField
                    
                    // Priority Selection
                    prioritySection
                }
                .standardHorizontalPadding()
                .padding(.vertical, AppSpacing.lg)
            }
            
            // Action Buttons
            if isEditing {
                deleteButton
            }
        }
        .background(AppColors.background)
        .onAppear {
            // Focus on name field when form appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isNameFocused = true
            }
        }
    }
    
    // MARK: - Header
    private var formHeader: some View {
        HStack {
            Button("Cancel") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    quickAddState.cancel()
                }
            }
            .captionStyle()
            .foregroundStyle(AppColors.secondaryText)
            
            Spacer()
            
            Text(formTitle)
                .subtitleStyle()
                .foregroundStyle(AppColors.primaryText)
            
            Spacer()
            
            Button("Save") {
                saveTask()
            }
            .captionStyle()
            .foregroundStyle(canSave ? AppColors.primary : AppColors.tertiaryText)
            .disabled(!canSave)
        }
        .standardHorizontalPadding()
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.cardBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(AppColors.secondaryText.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    // MARK: - Form Fields
    private var nameField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Name")
                .captionStyle()
                .foregroundStyle(AppColors.secondaryText)
            
            TextField("Enter task name", text: $name)
                .textFieldStyle(.roundedBorder)
                .focused($isNameFocused)
        }
    }
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Description")
                .captionStyle()
                .foregroundStyle(AppColors.secondaryText)
            
            TextEditor(text: $taskDescription)
                .focused($isDescriptionFocused)
                .frame(minHeight: 80)
                .padding(AppSpacing.sm)
                .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.secondaryText.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private var dueDateField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Due Date")
                .captionStyle()
                .foregroundStyle(AppColors.secondaryText)
            
            DatePicker("Select date and time", 
                      selection: $dueDate,
                      displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
        }
    }
    
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Priority")
                .captionStyle()
                .foregroundStyle(AppColors.secondaryText)
            
            VStack(spacing: AppSpacing.xs) {
                ForEach(TaskPriority.allCases, id: \.self) { priority in
                    priorityButton(for: priority)
                }
            }
        }
    }
    
    private func priorityButton(for priority: TaskPriority) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPriority = priority
            }
        }) {
            HStack {
                Image(systemName: selectedPriority == priority ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedPriority == priority ? priorityColor(for: priority) : AppColors.tertiaryText)
                
                Text(priority.rawValue)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.primaryText)
                
                Spacer()
                
                Circle()
                    .fill(priorityColor(for: priority))
                    .frame(width: 12, height: 12)
            }
            .padding(AppSpacing.md)
            .background(
                selectedPriority == priority ? priorityColor(for: priority).opacity(0.1) : AppColors.cardBackground,
                in: RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                    .stroke(
                        selectedPriority == priority ? priorityColor(for: priority).opacity(0.3) : AppColors.secondaryText.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .pressableStyle()
    }
    
    private func priorityColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .urgent: return .purple
        }
    }
    
    // MARK: - Delete Button
    private var deleteButton: some View {
        VStack(spacing: AppSpacing.sm) {
            Button("Delete Task") {
                deleteTask()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
            .foregroundStyle(.red)
            .pressableStyle()
        }
        .standardHorizontalPadding()
        .padding(.vertical, AppSpacing.lg)
        .background(AppColors.cardBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
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