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
        
        print("📱 Loaded: \(tasks.count) tasks, \(habits.count) habits, \(habitInstances.count) instances")
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
        updatedTask.completedAt = updatedTask.isCompleted ? Date() : nil
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
        saveData(medications, to: "medications")
    }
    
    // MARK: - Private Methods
    
    private func saveData<T: Encodable>(_ data: T, to fileName: String) {
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
        
        saveData(tasks, to: "tasks")
        saveData(habits, to: "habits")
        saveData(habitInstances, to: "habit_instances")
        saveData(medications, to: "medications")
        
        print("🗑️ All data cleared")
    }
}