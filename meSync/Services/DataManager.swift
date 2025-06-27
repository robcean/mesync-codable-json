//
//  DataManager.swift
//  meSync
//
//  Gestor central de datos con persistencia JSON
//

import Foundation
import SwiftUI

@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    // Published properties para que las vistas se actualicen automáticamente
    @Published var tasks: [TaskModel] = []
    @Published var habits: [HabitModel] = []
    @Published var habitInstances: [HabitInstanceModel] = []
    @Published var medications: [MedicationModel] = []
    @Published var medicationInstances: [MedicationInstanceModel] = []
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let documentsDirectory: URL
    
    private init() {
        // Configurar directorio de documentos
        documentsDirectory = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
        
        // Configurar encoder/decoder
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        
        // Cargar datos al iniciar
        loadAllData()
    }
    
    // MARK: - Public Methods
    
    func loadAllData() {
        tasks = loadData([TaskModel].self, from: "tasks") ?? []
        habits = loadData([HabitModel].self, from: "habits") ?? []
        habitInstances = loadData([HabitInstanceModel].self, from: "habit_instances") ?? []
        medications = loadData([MedicationModel].self, from: "medications") ?? []
        medicationInstances = loadData([MedicationInstanceModel].self, from: "medication_instances") ?? []
        
        print("📱 Loaded: \(tasks.count) tasks, \(habits.count) habits, \(habitInstances.count) habit instances, \(medications.count) medications")
    }
    
    // MARK: - Tasks
    
    func saveTask(_ task: TaskModel) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        } else {
            tasks.append(task)
        }
        saveData(tasks, to: "tasks")
    }
    
    func deleteTask(_ task: TaskModel) {
        tasks.removeAll { $0.id == task.id }
        saveData(tasks, to: "tasks")
    }
    
    func toggleTaskCompletion(_ task: TaskModel) {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        updatedTask.isSkipped = false  // Clear skip when completing
        updatedTask.completedAt = updatedTask.isCompleted ? Date() : nil
        updatedTask.skippedAt = nil
        updatedTask.updatedAt = Date()
        saveTask(updatedTask)
    }
    
    // MARK: - Habits
    
    func saveHabit(_ habit: HabitModel) {
        var updatedHabit = habit
        updatedHabit.updatedAt = Date()
        
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = updatedHabit
        } else {
            habits.append(updatedHabit)
        }
        saveData(habits, to: "habits")
    }
    
    func deleteHabit(_ habit: HabitModel) {
        habits.removeAll { $0.id == habit.id }
        // También eliminar todas las instancias de este hábito
        habitInstances.removeAll { $0.habitId == habit.id }
        saveData(habits, to: "habits")
        saveData(habitInstances, to: "habit_instances")
    }
    
    // MARK: - Habit Instances
    
    func getHabitInstance(for habitId: UUID, on date: Date) -> HabitInstanceModel? {
        let calendar = Calendar.current
        return habitInstances.first { instance in
            instance.habitId == habitId &&
            calendar.isDate(instance.scheduledDate, inSameDayAs: date)
        }
    }
    
    func toggleHabitCompletion(for habitId: UUID, on date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        if let existingInstance = getHabitInstance(for: habitId, on: date) {
            // Toggle existing instance
            var updatedInstance = existingInstance
            if updatedInstance.isCompleted {
                updatedInstance.completedAt = nil
            } else {
                updatedInstance.completedAt = Date()
                updatedInstance.skippedAt = nil
            }
            
            if let index = habitInstances.firstIndex(where: { $0.id == existingInstance.id }) {
                habitInstances[index] = updatedInstance
            }
        } else {
            // Create new instance
            let newInstance = HabitInstanceModel(
                habitId: habitId,
                scheduledDate: startOfDay,
                completedAt: Date()
            )
            habitInstances.append(newInstance)
        }
        
        saveData(habitInstances, to: "habit_instances")
    }
    
    func skipHabit(for habitId: UUID, on date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        if let existingInstance = getHabitInstance(for: habitId, on: date) {
            // Update existing instance
            var updatedInstance = existingInstance
            updatedInstance.skippedAt = Date()
            updatedInstance.completedAt = nil
            
            if let index = habitInstances.firstIndex(where: { $0.id == existingInstance.id }) {
                habitInstances[index] = updatedInstance
            }
        } else {
            // Create new instance
            let newInstance = HabitInstanceModel(
                habitId: habitId,
                scheduledDate: startOfDay,
                skippedAt: Date()
            )
            habitInstances.append(newInstance)
        }
        
        saveData(habitInstances, to: "habit_instances")
    }
    
    // MARK: - Medications
    
    func saveMedication(_ medication: MedicationModel) {
        var updatedMedication = medication
        updatedMedication.updatedAt = Date()
        
        if let index = medications.firstIndex(where: { $0.id == medication.id }) {
            medications[index] = updatedMedication
        } else {
            medications.append(updatedMedication)
        }
        saveData(medications, to: "medications")
    }
    
    func deleteMedication(_ medication: MedicationModel) {
        medications.removeAll { $0.id == medication.id }
        // También eliminar todas las instancias de este medicamento
        medicationInstances.removeAll { $0.medicationId == medication.id }
        saveData(medications, to: "medications")
        saveData(medicationInstances, to: "medication_instances")
    }
    
    // MARK: - Medication Instances
    
    func getMedicationInstance(for medicationId: UUID, on date: Date, doseNumber: Int) -> MedicationInstanceModel? {
        let calendar = Calendar.current
        return medicationInstances.first { instance in
            instance.medicationId == medicationId &&
            instance.doseNumber == doseNumber &&
            calendar.isDate(instance.scheduledDate, inSameDayAs: date)
        }
    }
    
    func toggleMedicationCompletion(for medicationId: UUID, on date: Date, doseNumber: Int) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        if let existingInstance = getMedicationInstance(for: medicationId, on: date, doseNumber: doseNumber) {
            // Toggle existing instance
            var updatedInstance = existingInstance
            if updatedInstance.isCompleted {
                updatedInstance.completedAt = nil
            } else {
                updatedInstance.completedAt = Date()
                updatedInstance.skippedAt = nil
            }
            
            if let index = medicationInstances.firstIndex(where: { $0.id == existingInstance.id }) {
                medicationInstances[index] = updatedInstance
            }
        } else {
            // Create new instance
            let newInstance = MedicationInstanceModel(
                medicationId: medicationId,
                scheduledDate: startOfDay,
                doseNumber: doseNumber,
                completedAt: Date()
            )
            medicationInstances.append(newInstance)
        }
        
        saveData(medicationInstances, to: "medication_instances")
    }
    
    func skipMedication(for medicationId: UUID, on date: Date, doseNumber: Int) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        if let existingInstance = getMedicationInstance(for: medicationId, on: date, doseNumber: doseNumber) {
            // Update existing instance
            var updatedInstance = existingInstance
            updatedInstance.skippedAt = Date()
            updatedInstance.completedAt = nil
            
            if let index = medicationInstances.firstIndex(where: { $0.id == existingInstance.id }) {
                medicationInstances[index] = updatedInstance
            }
        } else {
            // Create new instance
            let newInstance = MedicationInstanceModel(
                medicationId: medicationId,
                scheduledDate: startOfDay,
                doseNumber: doseNumber,
                skippedAt: Date()
            )
            medicationInstances.append(newInstance)
        }
        
        saveData(medicationInstances, to: "medication_instances")
    }
    
    // MARK: - Public Save Method (needed by ItemCard)
    
    func saveData<T: Encodable>(_ data: T, to fileName: String) {
        let url = documentsDirectory.appendingPathComponent("\(fileName).json")
        
        do {
            let encoded = try encoder.encode(data)
            try encoded.write(to: url, options: .atomic)
            print("✅ Saved \(fileName)")
        } catch {
            print("❌ Failed to save \(fileName): \(error)")
        }
    }
    
    private func loadData<T: Decodable>(_ type: T.Type, from fileName: String) -> T? {
        let url = documentsDirectory.appendingPathComponent("\(fileName).json")
        
        do {
            let data = try Data(contentsOf: url)
            let decoded = try decoder.decode(type, from: data)
            return decoded
        } catch {
            print("⚠️ Failed to load \(fileName): \(error)")
            return nil
        }
    }
    
    // MARK: - Debug Helpers
    
    func printStorageLocation() {
        print("📁 Storage location: \(documentsDirectory.path)")
    }
    
    func clearAllData() {
        tasks = []
        habits = []
        habitInstances = []
        medications = []
        medicationInstances = []
        
        saveData(tasks, to: "tasks")
        saveData(habits, to: "habits")
        saveData(habitInstances, to: "habit_instances")
        saveData(medications, to: "medications")
        saveData(medicationInstances, to: "medication_instances")
        
        print("🗑️ All data cleared")
    }
    
    // MARK: - Test Data
    func createTestData() {
        // Clear existing data first
        clearAllData()
        
        // Create test tasks
        let task1 = TaskModel(
            name: "Review project documentation",
            taskDescription: "Go through the CLAUDE.md file and update it",
            priority: .high,
            dueDate: Date().addingTimeInterval(3600) // 1 hour from now
        )
        
        let task2 = TaskModel(
            name: "Team meeting",
            taskDescription: "Weekly sync with the development team",
            priority: .medium,
            dueDate: Date().addingTimeInterval(7200) // 2 hours from now
        )
        
        let task3 = TaskModel(
            name: "Fix bug in login screen",
            taskDescription: "Users report the login button is not responsive",
            priority: .urgent,
            dueDate: Date().addingTimeInterval(1800) // 30 minutes from now
        )
        
        // Create test habits
        let habit1 = HabitModel(
            name: "Morning Exercise",
            habitDescription: "30 minutes of cardio or strength training",
            frequency: .daily,
            remindAt: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date(),
            dailyInterval: 1
        )
        
        let habit2 = HabitModel(
            name: "Read for 20 minutes",
            habitDescription: "Read a book before bed",
            frequency: .daily,
            remindAt: Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date(),
            dailyInterval: 1
        )
        
        let habit3 = HabitModel(
            name: "Weekly Planning",
            habitDescription: "Plan the upcoming week's tasks and goals",
            frequency: .weekly,
            remindAt: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date(),
            weeklyInterval: 1,
            selectedWeekdays: [7] // Sunday
        )
        
        // Create test medication
        let medication1 = MedicationModel(
            name: "Vitamin D",
            medicationDescription: "Daily vitamin supplement",
            instructions: "Take with breakfast",
            timesPerDay: 1,
            reminderTimes: [Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()]
        )
        
        // Save all test data
        saveTask(task1)
        saveTask(task2)
        saveTask(task3)
        saveHabit(habit1)
        saveHabit(habit2)
        saveHabit(habit3)
        saveMedication(medication1)
        
        print("✅ Test data created successfully!")
        print("📝 Created \(tasks.count) tasks, \(habits.count) habits, and \(medications.count) medication")
    }
}