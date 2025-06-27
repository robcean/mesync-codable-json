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
            // Header
            formHeader
            
            // Form Content
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
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
        .onAppear {
            loadFormData()
            isNameFocused = true
        }
    }
    
    // MARK: - Form Header
    private var formHeader: some View {
        HStack {
            Text(formTitle)
                .sectionTitleStyle()
            
            Spacer()
        }
        .headerContainerStyle()
    }
    
    // MARK: - Form Fields
    private var nameField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Name")
                .subtitleStyle()
            
            TextField("Enter medication name", text: $name)
                .textFieldStyle(.roundedBorder)
                .focused($isNameFocused)
        }
    }
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Description")
                .subtitleStyle()
            
            DynamicHeightTextEditor(
                text: $medicationDescription,
                placeholder: "What is this medication for?"
            )
        }
    }
    
    private var instructionsField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Instructions")
                .subtitleStyle()
            
            DynamicHeightTextEditor(
                text: $instructions,
                placeholder: "How to take this medication"
            )
        }
    }
    
    // MARK: - Times Per Day Section (Simplified for now)
    private var timesPerDaySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Times per day")
                .subtitleStyle()
            
            Text("1 time daily")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.primaryText)
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
        }
    }
    
    // MARK: - Reminder Time Section
    private var reminderTimeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Reminder time")
                .subtitleStyle()
            
            CompactTimePicker(
                title: "Time",
                time: $reminderTime
            )
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                // Cancel Button
                Button("Cancel") {
                    cancelAction()
                }
                .secondaryActionButtonStyle()
                .pressableStyle()
                
                // Save Button
                Button("Save") {
                    saveAction()
                }
                .primaryActionButtonStyle()
                .pressableStyle()
                .disabled(!isValidForm)
            }
            
            // Delete Button (only when editing)
            if isEditing {
                Button("Delete") {
                    deleteAction()
                }
                .destructiveButtonStyle()
                .pressableStyle()
            }
        }
        .standardPadding()
        .background(AppColors.headerMaterial)
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