//
//  HomeView.swift
//  meSync
//
//  Vista principal del Home con header, Quick Add e ítems del día
//

import SwiftUI

struct HomeView: View {
    @Binding var quickAddState: QuickAddState
    @EnvironmentObject var dataManager: DataManager
    @State private var taskFormCounter = 0
    @State private var habitFormCounter = 0
    @State private var selectedTab: Tab = .home
    
    enum Tab {
        case home
        case habit
        case task
        case medication
        case progress
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header fijo
            headerView
            
            // Contenido central scrollable
            Group {
                switch selectedTab {
                case .home:
                    ScrollView {
                        VStack(spacing: 0) {
                            // Quick Add Content (cuando esté activo)
                            quickAddContent
                            
                            // Lista de ítems del día
                            ItemsListView(quickAddState: $quickAddState)
                                .padding(.top, quickAddState == .hidden ? AppSpacing.sm : AppSpacing.lg)
                        }
                    }
                case .habit:
                    HabitsView(quickAddState: $quickAddState)
                case .task:
                    TasksView(quickAddState: $quickAddState)
                case .medication:
                    MedicationsView(quickAddState: $quickAddState)
                case .progress:
                    ProgressView(quickAddState: $quickAddState)
                }
            }
            
            // Tab bar fijo
            tabBarView
        }
        .mainContainerStyle()
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("meSync")
                        .primaryTitleStyle()
                    
                    Text(currentDateString)
                        .dateTextStyle()
                }
                
                Spacer()
                
                if selectedTab == .home {
                    Button("Quick Add") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            toggleQuickAdd()
                        }
                    }
                    .primaryButtonStyle()
                    .pressableStyle()
                }
            }
        }
        .headerContainerStyle()
    }
    
    // MARK: - Quick Add Content
    @ViewBuilder
    private var quickAddContent: some View {
        switch quickAddState {
        case .hidden:
            EmptyView()
            
        case .accordion:
            quickAddAccordion
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            
        case .taskForm(let editingTask):
            TaskFormView(quickAddState: $quickAddState)
                .id("taskForm-\(editingTask?.id.uuidString ?? "new-\(taskFormCounter)")")
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            
        case .habitForm(let editingHabit):
            HabitFormView(quickAddState: $quickAddState)
                .id("habitForm-\(editingHabit?.id.uuidString ?? "new-\(habitFormCounter)")")
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            
        case .medicationForm(let editingMedication):
            MedicationFormView(quickAddState: $quickAddState)
                .id("medicationForm-\(editingMedication?.id.uuidString ?? "new")")
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        }
    }
    
    // MARK: - Quick Add Accordion
    private var quickAddAccordion: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.lg) {
                QuickAddButton(
                    title: "Habit", 
                    systemImage: AppIcons.habitCircle,
                    action: { showHabitForm() }
                )
                
                QuickAddButton(
                    title: "Task", 
                    systemImage: AppIcons.taskCircle,
                    action: { showTaskForm() }
                )
                
                QuickAddButton(
                    title: "Medication", 
                    systemImage: AppIcons.medicationCircle,
                    action: { showMedicationForm() }
                )
            }
        }
        .sectionCardStyle()
        .padding(.top, AppSpacing.sm)
    }
    
    // MARK: - Placeholder Form View
    private func placeholderFormView(title: String) -> some View {
        VStack(spacing: AppSpacing.xl) {
            Text(title)
                .sectionTitleStyle()
            
            Text("Coming Soon")
                .subtitleStyle()
            
            Button("Cancel") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    quickAddState.cancel()
                }
            }
            .secondaryActionButtonStyle()
            .pressableStyle()
        }
        .sectionCardStyle()
        .padding(.top, AppSpacing.sm)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Tab Bar View
    private var tabBarView: some View {
        HStack {
            Spacer()
            
            TabBarButton(
                title: "Home", 
                systemImage: AppIcons.home,
                isSelected: selectedTab == .home,
                action: { selectedTab = .home }
            )
            
            Spacer()
            
            TabBarButton(
                title: "Habit", 
                systemImage: AppIcons.habit,
                isSelected: selectedTab == .habit,
                action: { selectedTab = .habit }
            )
            
            Spacer()
            
            TabBarButton(
                title: "Task", 
                systemImage: AppIcons.task,
                isSelected: selectedTab == .task,
                action: { selectedTab = .task }
            )
            
            Spacer()
            
            TabBarButton(
                title: "Medication", 
                systemImage: AppIcons.medication,
                isSelected: selectedTab == .medication,
                action: { selectedTab = .medication }
            )
            
            Spacer()
            
            TabBarButton(
                title: "Progress", 
                systemImage: AppIcons.progress,
                isSelected: selectedTab == .progress,
                action: { selectedTab = .progress }
            )
            
            Spacer()
        }
        .tabBarContainerStyle()
    }
    
    // MARK: - Actions
    private func toggleQuickAdd() {
        switch quickAddState {
        case .hidden:
            quickAddState = .accordion
        case .accordion, .taskForm, .habitForm, .medicationForm:
            quickAddState = .hidden
        }
    }
    
    private func showTaskForm() {
        // Increment counter to force view recreation for new tasks
        taskFormCounter += 1
        
        withAnimation(.easeInOut(duration: 0.3)) {
            quickAddState = .taskForm(editingTask: nil)
        }
    }
    
    private func showHabitForm() {
        // Increment counter to force view recreation for new habits
        habitFormCounter += 1
        
        withAnimation(.easeInOut(duration: 0.3)) {
            quickAddState = .habitForm(editingHabit: nil)
        }
    }
    
    private func showMedicationForm() {
        withAnimation(.easeInOut(duration: 0.3)) {
            quickAddState = .medicationForm(editingMedication: nil)
        }
    }
    
    // MARK: - Computed Properties
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: Date())
    }
    
    // MARK: - Placeholder View
    private func placeholderView(title: String, icon: String) -> some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(AppColors.tertiaryText)
            
            Text(title)
                .sectionTitleStyle()
                .foregroundStyle(AppColors.secondaryText)
            
            Text("Coming Soon")
                .captionStyle()
                .foregroundStyle(AppColors.tertiaryText)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

#Preview {
    @Previewable @State var quickAddState: QuickAddState = .hidden
    return HomeView(quickAddState: $quickAddState)
        .environmentObject(DataManager.shared)
} 