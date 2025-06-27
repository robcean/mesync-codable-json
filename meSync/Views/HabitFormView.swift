//
//  HabitFormView.swift
//  meSync
//
//  Formulario para crear y editar hábitos (migrado a Codable)
//

import SwiftUI

struct HabitFormView: View {
    @Binding var quickAddState: QuickAddState
    @EnvironmentObject var dataManager: DataManager
    
    // Habit data
    @State private var name: String = ""
    @State private var habitDescription: String = ""
    @State private var remindAt: Date = Date()
    @State private var selectedFrequency: HabitFrequency = .noRepetition
    
    // Daily repetition
    @State private var dailyInterval: Int = 1
    
    // Weekly repetition
    @State private var weeklyInterval: Int = 1
    @State private var selectedWeekdays: Set<Int> = []
    
    // Monthly repetition
    @State private var monthlyInterval: Int = 1
    @State private var selectedDayOfMonth: Int = 1
    
    // Custom repetition
    @State private var customDays: Set<Int> = []
    
    // Focus management
    @FocusState private var isNameFocused: Bool
    @FocusState private var isDescriptionFocused: Bool
    
    // Editing habit reference
    private let editingHabit: HabitModel?
    
    // Computed properties
    private var isEditing: Bool {
        editingHabit != nil
    }
    
    private var formTitle: String {
        isEditing ? "Editing Habit" : "Creating Habit"
    }
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Initializer
    init(quickAddState: Binding<QuickAddState>) {
        self._quickAddState = quickAddState
        
        // Extract editing habit if available
        if case .habitForm(let habit) = quickAddState.wrappedValue {
            self.editingHabit = habit
            self._name = State(initialValue: habit?.name ?? "")
            self._habitDescription = State(initialValue: habit?.habitDescription ?? "")
            self._remindAt = State(initialValue: habit?.remindAt ?? Date())
            self._selectedFrequency = State(initialValue: habit?.frequency ?? .noRepetition)
            self._dailyInterval = State(initialValue: habit?.dailyInterval ?? 1)
            self._weeklyInterval = State(initialValue: habit?.weeklyInterval ?? 1)
            self._selectedWeekdays = State(initialValue: Set(habit?.selectedWeekdays ?? []))
            self._monthlyInterval = State(initialValue: habit?.monthlyInterval ?? 1)
            self._selectedDayOfMonth = State(initialValue: habit?.selectedDayOfMonth ?? 1)
            self._customDays = State(initialValue: Set(habit?.customDays ?? []))
        } else {
            self.editingHabit = nil
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            formHeader
            
            // Form Content
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    formFields
                    dateTimeSection
                    frequencySection
                    
                    // Conditional fields based on frequency
                    if selectedFrequency == .daily {
                        dailyIntervalField
                    } else if selectedFrequency == .weekly {
                        weeklyFields
                    } else if selectedFrequency == .monthly {
                        monthlyFields
                    } else if selectedFrequency == .custom {
                        customFields
                    }
                    
                    Spacer(minLength: AppSpacing.xxxl)
                }
                .standardPadding()
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
            
            // Auto-select current day when choosing weekly
            if selectedFrequency == .weekly && selectedWeekdays.isEmpty {
                let calendar = Calendar.current
                let weekday = calendar.component(.weekday, from: Date())
                let adjustedWeekday = weekday == 1 ? 7 : weekday - 1 // Convert to Monday=1 format
                selectedWeekdays.insert(adjustedWeekday)
            }
        }
    }
    
    // MARK: - Form Header
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
                saveHabit()
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
                .frame(height: AppDimensions.dividerHeight)
                .foregroundStyle(AppColors.secondaryText.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    // MARK: - Form Fields
    private var formFields: some View {
        VStack(spacing: AppSpacing.lg) {
            // Name Field
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Name")
                    .captionStyle()
                    .foregroundStyle(AppColors.secondaryText)
                
                TextField("Enter habit name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .focused($isNameFocused)
            }
            
            // Description Field
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Description")
                    .captionStyle()
                    .foregroundStyle(AppColors.secondaryText)
                
                TextEditor(text: $habitDescription)
                    .focused($isDescriptionFocused)
                    .frame(minHeight: AppDimensions.minTextEditorHeight)
                    .padding(AppSpacing.sm)
                    .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.mediumCornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSpacing.mediumCornerRadius)
                            .stroke(AppColors.secondaryText.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
    
    // MARK: - Date Time Section
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Date and Time")
                .captionStyle()
                .foregroundStyle(AppColors.secondaryText)
            
            CompactDatePicker(
                title: "Start Date",
                date: $remindAt,
                components: .date
            )
            
            CompactTimePicker(
                title: "Reminder Time",
                time: $remindAt
            )
        }
    }
    
    // MARK: - Frequency Section
    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Repeat")
                .captionStyle()
                .foregroundStyle(AppColors.secondaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach([HabitFrequency.noRepetition, .daily, .weekly, .monthly, .custom], id: \.self) { frequency in
                        frequencyChip(for: frequency)
                    }
                }
                .padding(.horizontal, 1) // Small padding to ensure content isn't cut off
            }
        }
    }
    
    private func frequencyChip(for frequency: HabitFrequency) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFrequency = frequency
                
                // Auto-select current day when choosing weekly
                if frequency == .weekly && selectedWeekdays.isEmpty {
                    let calendar = Calendar.current
                    let weekday = calendar.component(.weekday, from: Date())
                    let adjustedWeekday = weekday == 1 ? 7 : weekday - 1 // Convert to Monday=1 format
                    selectedWeekdays.insert(adjustedWeekday)
                }
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: selectedFrequency == frequency ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(selectedFrequency == frequency ? AppColors.onPrimaryText : AppColors.tertiaryText)
                
                Text(frequency.rawValue)
                    .font(AppTypography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(selectedFrequency == frequency ? AppColors.onPrimaryText : AppColors.primaryText)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                selectedFrequency == frequency ? AppColors.primary : AppColors.cardBackground,
                in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                    .stroke(
                        selectedFrequency == frequency ? AppColors.primary : AppColors.secondaryText.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .pressableStyle()
    }
    
    // MARK: - Daily Interval Field
    private var dailyIntervalField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Every")
                .captionStyle()
                .foregroundStyle(AppColors.secondaryText)
            
            HStack {
                TextField("1", value: $dailyInterval, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(width: 60)
                
                Text(dailyInterval == 1 ? "day" : "days")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.primaryText)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Weekly Fields
    private var weeklyFields: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Weekly interval
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Every")
                    .captionStyle()
                    .foregroundStyle(AppColors.secondaryText)
                
                HStack {
                    TextField("1", value: $weeklyInterval, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                    
                    Text(weeklyInterval == 1 ? "week" : "weeks")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.primaryText)
                    
                    Spacer()
                }
            }
            
            // Weekday selector
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("On days")
                    .captionStyle()
                    .foregroundStyle(AppColors.secondaryText)
                
                weekdaySelector
            }
        }
    }
    
    private var weekdaySelector: some View {
        let weekdays = [
            (1, "Mon"), (2, "Tue"), (3, "Wed"), (4, "Thu"),
            (5, "Fri"), (6, "Sat"), (7, "Sun")
        ]
        
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: AppSpacing.xs) {
            ForEach(weekdays, id: \.0) { day, label in
                Button(action: {
                    if selectedWeekdays.contains(day) {
                        selectedWeekdays.remove(day)
                    } else {
                        selectedWeekdays.insert(day)
                    }
                }) {
                    Text(label)
                        .font(AppTypography.caption)
                        .foregroundStyle(selectedWeekdays.contains(day) ? AppColors.onPrimaryText : AppColors.primaryText)
                        .frame(width: 40, height: 32)
                        .background(
                            selectedWeekdays.contains(day) ? AppColors.primary : AppColors.cardBackground,
                            in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                                .stroke(
                                    selectedWeekdays.contains(day) ? AppColors.primary : AppColors.secondaryText.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                }
                .pressableStyle()
            }
        }
    }
    
    // MARK: - Monthly Fields
    private var monthlyFields: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Monthly interval
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Every")
                    .captionStyle()
                    .foregroundStyle(AppColors.secondaryText)
                
                HStack {
                    TextField("1", value: $monthlyInterval, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                    
                    Text(monthlyInterval == 1 ? "month" : "months")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.primaryText)
                    
                    Spacer()
                }
            }
            
            // Day of month selector
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("On day")
                    .captionStyle()
                    .foregroundStyle(AppColors.secondaryText)
                
                HStack {
                    TextField("1", value: $selectedDayOfMonth, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                    
                    Text("of the month")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.primaryText)
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Custom Fields
    private var customFields: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Select days of the month")
                .captionStyle()
                .foregroundStyle(AppColors.secondaryText)
            
            customDaySelector
        }
    }
    
    private var customDaySelector: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: AppSpacing.xs) {
            ForEach(1...31, id: \.self) { day in
                Button(action: {
                    if customDays.contains(day) {
                        customDays.remove(day)
                    } else {
                        customDays.insert(day)
                    }
                }) {
                    Text("\(day)")
                        .font(AppTypography.caption)
                        .foregroundStyle(customDays.contains(day) ? AppColors.onPrimaryText : AppColors.primaryText)
                        .frame(width: 32, height: 32)
                        .background(
                            customDays.contains(day) ? AppColors.primary : AppColors.cardBackground,
                            in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                                .stroke(
                                    customDays.contains(day) ? AppColors.primary : AppColors.secondaryText.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                }
                .pressableStyle()
            }
        }
    }
    
    // MARK: - Delete Button
    private var deleteButton: some View {
        VStack(spacing: AppSpacing.sm) {
            Button("Delete Habit", role: .destructive) {
                deleteHabit()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
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
    private func saveHabit() {
        guard canSave else { return }
        
        var habit = HabitModel(
            id: editingHabit?.id ?? UUID(),
            name: name,
            habitDescription: habitDescription,
            frequency: selectedFrequency,
            remindAt: remindAt,
            dailyInterval: dailyInterval,
            weeklyInterval: weeklyInterval,
            selectedWeekdays: Array(selectedWeekdays).sorted(),
            monthlyInterval: monthlyInterval,
            selectedDayOfMonth: selectedDayOfMonth,
            customDays: Array(customDays).sorted()
        )
        
        // Set dates manually
        if let existingHabit = editingHabit {
            habit.createdAt = existingHabit.createdAt
        }
        habit.updatedAt = Date()
        
        dataManager.saveHabit(habit)
        
        // Close form
        withAnimation(.easeInOut(duration: 0.3)) {
            quickAddState.hide()
        }
    }
    
    private func deleteHabit() {
        guard let habit = editingHabit else { return }
        
        dataManager.deleteHabit(habit)
        
        // Close form
        withAnimation(.easeInOut(duration: 0.3)) {
            quickAddState.hide()
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var quickAddState: QuickAddState = .habitForm()
    
    HabitFormView(quickAddState: $quickAddState)
        .environmentObject(DataManager.shared)
}