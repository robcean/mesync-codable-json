//
//  ProgressView.swift
//  meSync
//
//  Vista para mostrar el historial de items completados y saltados
//

import SwiftUI

struct ProgressView: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var quickAddState: QuickAddState
    
    // Filter states
    @State private var selectedFilter: FilterType = .all
    @State private var searchText = ""
    @State private var itemsShown = 30
    
    enum FilterType: String, CaseIterable {
        case all = "All"
        case tasks = "Tasks"
        case habits = "Habits"
        case medicine = "Medicine"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            // Content
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Filter buttons
                    filterButtons
                    
                    // Search bar
                    searchBar
                    
                    // Items list
                    LazyVStack(spacing: AppSpacing.md) {
                        ForEach(Array(filteredItems.prefix(itemsShown)), id: \.id) { item in
                            ProgressItemCard(
                                item: item,
                                quickAddState: $quickAddState
                            )
                        }
                        
                        // Load more button
                        if filteredItems.count > itemsShown {
                            loadMoreButton
                        }
                    }
                    .standardHorizontalPadding()
                    
                    if filteredItems.isEmpty {
                        emptyStateView
                    }
                }
                .padding(.top, AppSpacing.md)
            }
        }
        .mainContainerStyle()
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Text("Progress")
                .sectionTitleStyle()
            
            Spacer()
            
            Text("\(filteredItems.count) items")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.tertiaryText)
        }
        .headerContainerStyle()
    }
    
    // MARK: - Filter Buttons
    private var filterButtons: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(FilterType.allCases, id: \.self) { filter in
                filterButton(for: filter)
            }
        }
        .standardHorizontalPadding()
    }
    
    private func filterButton(for filter: FilterType) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFilter = filter
            }
        }) {
            Text(filter.rawValue)
                .font(AppTypography.caption)
                .foregroundStyle(selectedFilter == filter ? .white : AppColors.primaryText)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    selectedFilter == filter ? AppColors.primary : AppColors.cardBackground,
                    in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                )
        }
        .pressableStyle()
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.tertiaryText)
            
            TextField("Search items...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
        .standardHorizontalPadding()
    }
    
    // MARK: - Load More Button
    private var loadMoreButton: some View {
        Button(action: {
            withAnimation {
                itemsShown += 30
            }
        }) {
            Text("Load More")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.primary)
                .padding(.vertical, AppSpacing.md)
                .frame(maxWidth: .infinity)
                .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
        }
        .pressableStyle()
        .padding(.horizontal, AppSpacing.lg)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.secondaryText)
            
            Text("No completed items yet")
                .subtitleStyle()
                .multilineTextAlignment(.center)
            
            Text("Complete or skip items to see them here")
                .captionStyle()
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, AppSpacing.xxxl)
    }
    
    // MARK: - Computed Properties
    private var allCompletedItems: [any ItemProtocol] {
        var items: [any ItemProtocol] = []
        
        // Completed/skipped tasks
        items += dataManager.tasks.filter { $0.isCompleted || $0.isSkipped }
        
        // Generate completed/skipped habit instances
        let habitInstances = dataManager.habitInstances.compactMap { instance -> HabitInstance? in
            guard let habit = dataManager.habits.first(where: { $0.id == instance.habitId }),
                  instance.isCompleted || instance.isSkipped else { return nil }
            
            return HabitInstance(from: habit, for: instance.scheduledDate, instance: instance)
        }
        items += habitInstances
        
        // Generate completed/skipped medication instances
        let medicationInstances = dataManager.medicationInstances.compactMap { instance -> MedicationInstance? in
            guard let medication = dataManager.medications.first(where: { $0.id == instance.medicationId }),
                  instance.isCompleted || instance.isSkipped else { return nil }
            
            return MedicationInstance(
                from: medication,
                for: instance.scheduledDate,
                doseNumber: instance.doseNumber,
                instance: instance
            )
        }
        items += medicationInstances
        
        // Sort by most recent action
        return items.sorted { item1, item2 in
            let date1 = item1.actionTimestamp ?? Date.distantPast
            let date2 = item2.actionTimestamp ?? Date.distantPast
            return date1 > date2
        }
    }
    
    private var filteredItems: [any ItemProtocol] {
        var items = allCompletedItems
        
        // Apply type filter
        switch selectedFilter {
        case .all:
            break
        case .tasks:
            items = items.filter { $0 is TaskModel }
        case .habits:
            items = items.filter { $0 is HabitInstance }
        case .medicine:
            items = items.filter { $0 is MedicationInstance }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            items = items.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.itemDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return items
    }
}

// MARK: - Progress Item Card (without edit button)
struct ProgressItemCard: View {
    let item: any ItemProtocol
    @Binding var quickAddState: QuickAddState
    @EnvironmentObject private var dataManager: DataManager
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            HStack(spacing: AppSpacing.md) {
                // Status indicator
                statusIcon
                
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
                        Text("\(dateString)")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.secondaryText)
                        
                        if let timestamp = item.actionTimestamp {
                            Text("at \(timeString(from: timestamp))")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.tertiaryText)
                        }
                    }
                }
                
                Spacer()
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
                .stroke(borderColor, lineWidth: 2)
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
    
    // MARK: - Status Icon
    @ViewBuilder
    private var statusIcon: some View {
        if item.isCompleted {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: AppDimensions.mediumIcon))
                .foregroundStyle(.green)
        } else if item.isSkipped {
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: AppDimensions.mediumIcon))
                .foregroundStyle(.orange)
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
    
    // MARK: - Computed Properties
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: item.scheduledTime)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private var hasDescription: Bool {
        !item.itemDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var cardBackground: Color {
        if item.isCompleted {
            return Color.gray.opacity(0.15)
        } else if item.isSkipped {
            return Color.orange.opacity(0.1)
        } else {
            return AppColors.cardBackground
        }
    }
    
    private var textColor: Color {
        if item.isCompleted {
            return AppColors.primaryText.opacity(0.8)
        } else {
            return AppColors.primaryText
        }
    }
    
    private var borderColor: Color {
        if item.isCompleted {
            return Color.green.opacity(0.3)
        } else if item.isSkipped {
            return Color.orange.opacity(0.3)
        } else {
            return AppColors.primary.opacity(0.3)
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var quickAddState: QuickAddState = .hidden
    
    ProgressView(quickAddState: $quickAddState)
        .environmentObject(DataManager.shared)
}