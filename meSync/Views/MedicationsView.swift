//
//  MedicationsView.swift
//  meSync
//
//  Vista dedicada para gestionar todos los medicamentos
//

import SwiftUI

struct MedicationsView: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var quickAddState: QuickAddState
    
    // View states
    @State private var selectedTimeFilter: TimeFilter = .all
    @State private var searchText = ""
    @State private var showingSchedule = true
    
    enum TimeFilter: String, CaseIterable {
        case all = "All"
        case morning = "Morning"
        case afternoon = "Afternoon"
        case evening = "Evening"
        case night = "Night"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            // Content
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Today's schedule
                    if showingSchedule {
                        todayScheduleSection
                    }
                    
                    // Stats
                    statsSection
                    
                    // Time filter
                    timeFilterSection
                    
                    // Search bar
                    searchBar
                    
                    // Medications list
                    medicationsList
                }
                .padding(.top, AppSpacing.md)
            }
        }
        .mainContainerStyle()
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Text("Medications")
                .sectionTitleStyle()
            
            Spacer()
            
            // Add new medication button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    quickAddState = .medicationForm(editingMedication: nil)
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
    
    // MARK: - Today's Schedule Section
    private var todayScheduleSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Today's Schedule")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.primaryText)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        showingSchedule.toggle()
                    }
                }) {
                    Image(systemName: showingSchedule ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(AppColors.tertiaryText)
                }
            }
            
            if todayMedicationInstances.isEmpty {
                Text("No medications scheduled for today")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.tertiaryText)
                    .padding(.vertical, AppSpacing.md)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(todayMedicationInstances.sorted(by: { $0.scheduledTime < $1.scheduledTime }), id: \.id) { instance in
                        ScheduleRow(instance: instance)
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                .stroke(AppColors.primary.opacity(0.3), lineWidth: 2)
        )
        .standardHorizontalPadding()
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: AppSpacing.md) {
            StatCard(
                title: "Active",
                value: "\(dataManager.medications.count)",
                icon: "pills",
                color: .blue
            )
            
            StatCard(
                title: "Today",
                value: "\(todayDosesCount)",
                icon: "clock",
                color: .orange
            )
            
            StatCard(
                title: "Taken",
                value: "\(takenTodayCount)",
                icon: "checkmark.circle",
                color: .green
            )
        }
        .standardHorizontalPadding()
    }
    
    // MARK: - Time Filter
    private var timeFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(TimeFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedTimeFilter == filter,
                        action: { selectedTimeFilter = filter }
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
            
            TextField("Search medications...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
        .standardHorizontalPadding()
    }
    
    // MARK: - Medications List
    private var medicationsList: some View {
        LazyVStack(spacing: AppSpacing.md) {
            if filteredMedications.isEmpty {
                emptyStateView
            } else {
                ForEach(filteredMedications) { medication in
                    MedicationRow(
                        medication: medication,
                        quickAddState: $quickAddState,
                        onDelete: {
                            withAnimation {
                                dataManager.deleteMedication(medication)
                            }
                        },
                        onTakeNow: {
                            // TODO: Implement unscheduled dose
                            print("Take now: \(medication.name)")
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
            Image(systemName: "pills.circle")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.secondaryText)
            
            Text("No medications found")
                .subtitleStyle()
            
            Text("Add your medications to track doses")
                .captionStyle()
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, AppSpacing.xxxl)
    }
    
    // MARK: - Computed Properties
    private var todayMedicationInstances: [MedicationInstance] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var instances: [MedicationInstance] = []
        
        for medication in dataManager.medications {
            for doseNumber in 1...medication.timesPerDay {
                let existingInstance = dataManager.getMedicationInstance(
                    for: medication.id,
                    on: today,
                    doseNumber: doseNumber
                )
                
                let instance = MedicationInstance(
                    from: medication,
                    for: today,
                    doseNumber: doseNumber,
                    instance: existingInstance
                )
                instances.append(instance)
            }
        }
        
        return instances
    }
    
    private var todayDosesCount: Int {
        todayMedicationInstances.count
    }
    
    private var takenTodayCount: Int {
        todayMedicationInstances.filter { $0.isCompleted }.count
    }
    
    private var filteredMedications: [MedicationModel] {
        var medications = dataManager.medications
        
        // Apply time filter
        switch selectedTimeFilter {
        case .all:
            break
        case .morning:
            medications = medications.filter { med in
                med.reminderTimes.contains { time in
                    let hour = Calendar.current.component(.hour, from: time)
                    return hour >= 5 && hour < 12
                }
            }
        case .afternoon:
            medications = medications.filter { med in
                med.reminderTimes.contains { time in
                    let hour = Calendar.current.component(.hour, from: time)
                    return hour >= 12 && hour < 17
                }
            }
        case .evening:
            medications = medications.filter { med in
                med.reminderTimes.contains { time in
                    let hour = Calendar.current.component(.hour, from: time)
                    return hour >= 17 && hour < 21
                }
            }
        case .night:
            medications = medications.filter { med in
                med.reminderTimes.contains { time in
                    let hour = Calendar.current.component(.hour, from: time)
                    return hour >= 21 || hour < 5
                }
            }
        }
        
        // Apply search
        if !searchText.isEmpty {
            medications = medications.filter { med in
                med.name.localizedCaseInsensitiveContains(searchText) ||
                med.medicationDescription.localizedCaseInsensitiveContains(searchText) ||
                med.instructions.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return medications.sorted { $0.name < $1.name }
    }
}

// MARK: - Schedule Row Component
struct ScheduleRow: View {
    let instance: MedicationInstance
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Time
            Text(timeString)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 60, alignment: .leading)
            
            // Medication info
            VStack(alignment: .leading, spacing: 2) {
                Text(instance.name)
                    .font(AppTypography.body)
                    .foregroundStyle(instance.isCompleted ? AppColors.primaryText.opacity(0.6) : AppColors.primaryText)
                    .strikethrough(instance.isCompleted)
                
                if instance.originalMedication.timesPerDay > 1 {
                    Text("Dose \(instance.doseNumber) of \(instance.originalMedication.timesPerDay)")
                        .font(AppTypography.caption2)
                        .foregroundStyle(AppColors.tertiaryText)
                }
            }
            
            Spacer()
            
            // Status
            if instance.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: AppDimensions.smallIcon))
                    .foregroundStyle(.green)
            } else if instance.isSkipped {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: AppDimensions.smallIcon))
                    .foregroundStyle(.orange)
            } else {
                // Action buttons for pending doses
                HStack(spacing: AppSpacing.sm) {
                    Button(action: {
                        dataManager.skipMedication(
                            for: instance.originalMedication.id,
                            on: instance.instanceDate,
                            doseNumber: instance.doseNumber
                        )
                    }) {
                        Image(systemName: "arrow.right.circle")
                            .font(.system(size: AppDimensions.smallIcon))
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    .pressableStyle()
                    
                    Button(action: {
                        dataManager.toggleMedicationCompletion(
                            for: instance.originalMedication.id,
                            on: instance.instanceDate,
                            doseNumber: instance.doseNumber
                        )
                    }) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: AppDimensions.smallIcon))
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    .pressableStyle()
                }
            }
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                .fill(backgroundColor)
        )
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: instance.scheduledTime)
    }
    
    private var backgroundColor: Color {
        if instance.isCompleted {
            return Color.green.opacity(0.1)
        } else if instance.isSkipped {
            return Color.orange.opacity(0.1)
        } else if instance.scheduledTime < Date() {
            return Color.red.opacity(0.1)
        } else {
            return AppColors.cardBackground
        }
    }
}

// MARK: - Medication Row Component
struct MedicationRow: View {
    let medication: MedicationModel
    @Binding var quickAddState: QuickAddState
    let onDelete: () -> Void
    let onTakeNow: () -> Void
    @State private var showDeleteConfirm = false
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content
            HStack(spacing: AppSpacing.md) {
                // Medication icon
                Image(systemName: "pills.fill")
                    .font(.system(size: AppDimensions.smallIcon))
                    .foregroundStyle(.blue)
                    .frame(width: 32, height: 32)
                    .background(Color.blue.opacity(0.1), in: Circle())
                
                // Medication info
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(medication.name)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.primaryText)
                    
                    HStack(spacing: AppSpacing.sm) {
                        // Doses per day
                        Text("\(medication.timesPerDay)x daily")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.secondaryText)
                        
                        // Next dose time
                        if let nextDose = getNextDoseTime() {
                            Label(nextDose, systemImage: "clock")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.tertiaryText)
                        }
                    }
                }
                
                Spacer()
                
                // Expand indicator
                if !medication.instructions.isEmpty || !medication.medicationDescription.isEmpty {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(AppColors.tertiaryText)
                }
            }
            .padding(AppSpacing.lg)
            .contentShape(Rectangle())
            .onTapGesture {
                if !medication.instructions.isEmpty || !medication.medicationDescription.isEmpty {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }
            }
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Divider()
                        .background(AppColors.secondaryText.opacity(0.2))
                    
                    if !medication.medicationDescription.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Description")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.tertiaryText)
                            Text(medication.medicationDescription)
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.primaryText)
                        }
                    }
                    
                    if !medication.instructions.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Instructions")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.tertiaryText)
                            Text(medication.instructions)
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.primaryText)
                        }
                    }
                    
                    // Reminder times
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Reminder Times")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.tertiaryText)
                        
                        HStack(spacing: AppSpacing.sm) {
                            ForEach(medication.reminderTimes.indices, id: \.self) { index in
                                Text(timeString(from: medication.reminderTimes[index]))
                                    .font(AppTypography.caption)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .padding(.vertical, AppSpacing.xs)
                                    .background(AppColors.primary.opacity(0.1), in: Capsule())
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
            }
            
            // Actions bar
            HStack(spacing: 0) {
                // Take now button
                Button(action: onTakeNow) {
                    HStack {
                        Image(systemName: "hand.tap")
                            .font(.caption)
                        Text("Take Now")
                            .font(AppTypography.caption)
                    }
                    .foregroundStyle(AppColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                }
                .pressableStyle()
                
                Divider()
                    .frame(height: 20)
                
                // Edit button
                Button(action: {
                    quickAddState = .medicationForm(editingMedication: medication)
                }) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                }
                .pressableStyle()
                
                Divider()
                    .frame(height: 20)
                
                // Delete button
                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                }
                .pressableStyle()
            }
            .background(AppColors.secondaryText.opacity(0.05))
        }
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
        )
        .confirmationDialog(
            "Delete Medication?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will also delete all medication history.")
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func getNextDoseTime() -> String? {
        let now = Date()
        let calendar = Calendar.current
        
        // Find next dose time today
        for time in medication.reminderTimes {
            let todayTime = calendar.date(
                bySettingHour: calendar.component(.hour, from: time),
                minute: calendar.component(.minute, from: time),
                second: 0,
                of: now
            ) ?? now
            
            if todayTime > now {
                return "Next: \(timeString(from: todayTime))"
            }
        }
        
        // If no more doses today, show first dose tomorrow
        if let firstDose = medication.reminderTimes.first {
            return "Next: Tomorrow \(timeString(from: firstDose))"
        }
        
        return nil
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var quickAddState: QuickAddState = .hidden
    
    MedicationsView(quickAddState: $quickAddState)
        .environmentObject(DataManager.shared)
}