//
//  MedicationFormView.swift
//  meSync
//
//  Formulario para crear y editar medicamentos
//

import SwiftUI

struct MedicationFormView: View {
    @Binding var quickAddState: QuickAddState
    @EnvironmentObject var dataManager: DataManager
    
    // Form data
    @State private var name: String = ""
    @State private var medicationDescription: String = ""
    @State private var instructions: String = ""
    @State private var timesPerDay: Int = 1
    @State private var reminderTime: Date = Date()
    
    // UI State
    @FocusState private var isNameFocused: Bool
    @State private var editingMedication: MedicationModel?
    
    // Computed properties
    private var isEditing: Bool {
        editingMedication != nil
    }
    
    private var formTitle: String {
        isEditing ? "Edit Medication" : "Create New Medication"
    }
    
    private var isValidForm: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Form Content
            ScrollView {
                VStack(spacing: AppSpacing.xs) {
                    // Form Title
                    Text(isEditing ? "Edit Medication" : "Create New Medication")
                        .sectionTitleStyle()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, AppSpacing.sm)
                    
                    nameField
                    descriptionField
                    instructionsField
                    timesPerDaySection
                    reminderTimeSection
                    
                    Spacer(minLength: AppSpacing.xxxl)
                }
                .standardPadding()
            }
            
            // Action Buttons
            actionButtons
        }
        .formContainerStyle()
        .onAppear {
            loadFormData()
            isNameFocused = true
        }
    }
    
    // MARK: - Form Fields
    private var nameField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Name")
                .formLabelStyle()
                .foregroundStyle(AppColors.primaryText)
            
            TextField("Enter medication name", text: $name)
                .formInputStyle()
                .focused($isNameFocused)
        }
        .formSectionStyle()
    }
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Description")
                .formLabelStyle()
                .foregroundStyle(AppColors.primaryText)
            
            DynamicHeightTextEditor(
                text: $medicationDescription,
                placeholder: "What is this medication for?"
            )
        }
        .formSectionStyle()
    }
    
    private var instructionsField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Instructions")
                .formLabelStyle()
                .foregroundStyle(AppColors.primaryText)
            
            DynamicHeightTextEditor(
                text: $instructions,
                placeholder: "How to take this medication"
            )
        }
        .formSectionStyle()
    }
    
    // MARK: - Times Per Day Section (Simplified for now)
    private var timesPerDaySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Times per day")
                .formLabelStyle()
                .foregroundStyle(AppColors.primaryText)
            
            Text("1 time daily")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.primaryText)
                .formInputStyle()
        }
        .formSectionStyle()
    }
    
    // MARK: - Reminder Time Section
    private var reminderTimeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Reminder time")
                .formLabelStyle()
                .foregroundStyle(AppColors.primaryText)
            
            CompactTimePicker(
                title: "Time",
                time: $reminderTime
            )
        }
        .formSectionStyle()
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: AppSpacing.sm) {
            // Cancel and Save buttons
            HStack(spacing: AppSpacing.md) {
                Button("Cancel") {
                    cancelAction()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                
                Button("Save") {
                    saveAction()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(!isValidForm)
            }
            
            // Delete button (only when editing)
            if isEditing {
                Button("Delete Medication", role: .destructive) {
                    deleteAction()
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
    private func loadFormData() {
        // Extract editing medication data if available
        if case .medicationForm(let medication) = quickAddState,
           let med = medication {
            editingMedication = med
            name = med.name
            medicationDescription = med.medicationDescription
            instructions = med.instructions
            timesPerDay = med.timesPerDay
            if let firstReminder = med.reminderTimes.first {
                reminderTime = firstReminder
            }
        }
    }
    
    private func cancelAction() {
        isNameFocused = false
        
        withAnimation(.easeInOut(duration: 0.3)) {
            quickAddState.cancel()
        }
    }
    
    private func saveAction() {
        guard isValidForm else { return }
        
        isNameFocused = false
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let existing = editingMedication {
            // Update existing medication
            var updated = existing
            updated.name = trimmedName
            updated.medicationDescription = medicationDescription
            updated.instructions = instructions
            updated.timesPerDay = timesPerDay
            updated.reminderTimes = [reminderTime]
            updated.updatedAt = Date()
            
            dataManager.saveMedication(updated)
        } else {
            // Create new medication
            let newMedication = MedicationModel(
                name: trimmedName,
                medicationDescription: medicationDescription,
                instructions: instructions,
                timesPerDay: timesPerDay,
                reminderTimes: [reminderTime]
            )
            
            dataManager.saveMedication(newMedication)
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            quickAddState.hide()
        }
    }
    
    private func deleteAction() {
        guard let medication = editingMedication else { return }
        
        dataManager.deleteMedication(medication)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            quickAddState.hide()
        }
    }
}

// MARK: - Preview
#Preview("Creating Medication") {
    @Previewable @State var quickAddState: QuickAddState = .medicationForm()
    
    MedicationFormView(quickAddState: $quickAddState)
        .environmentObject(DataManager.shared)
}

#Preview("Editing Medication") {
    @Previewable @State var quickAddState: QuickAddState = .medicationForm(
        editingMedication: MedicationModel(
            name: "Aspirin",
            medicationDescription: "For headache relief",
            instructions: "Take with food",
            timesPerDay: 1,
            reminderTimes: [Date()]
        )
    )
    
    MedicationFormView(quickAddState: $quickAddState)
        .environmentObject(DataManager.shared)
}