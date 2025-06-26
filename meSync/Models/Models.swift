//
//  Models.swift
//  meSync
//
//  Modelos Codable para persistencia JSON y futura integración con Supabase
//

import Foundation

// MARK: - Task Model
struct TaskModel: Codable, Identifiable {
    let id: UUID
    var name: String
    var taskDescription: String
    var priority: TaskPriority
    var dueDate: Date
    var isCompleted: Bool
    var isSkipped: Bool
    var completedAt: Date?
    var skippedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String = "",
        taskDescription: String = "",
        priority: TaskPriority = .medium,
        dueDate: Date = Date(),
        isCompleted: Bool = false,
        isSkipped: Bool = false,
        completedAt: Date? = nil,
        skippedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.taskDescription = taskDescription
        self.priority = priority
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.isSkipped = isSkipped
        self.completedAt = completedAt
        self.skippedAt = skippedAt
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Habit Model
struct HabitModel: Codable, Identifiable {
    let id: UUID
    var name: String
    var habitDescription: String
    var frequency: HabitFrequency
    var remindAt: Date
    
    // Daily repetition
    var dailyInterval: Int
    
    // Weekly repetition
    var weeklyInterval: Int
    var selectedWeekdays: [Int]
    
    // Monthly repetition
    var monthlyInterval: Int
    var selectedDayOfMonth: Int
    
    // Custom repetition
    var customDays: [Int]
    
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String = "",
        habitDescription: String = "",
        frequency: HabitFrequency = .noRepetition,
        remindAt: Date = Date(),
        dailyInterval: Int = 1,
        weeklyInterval: Int = 1,
        selectedWeekdays: [Int] = [],
        monthlyInterval: Int = 1,
        selectedDayOfMonth: Int = 1,
        customDays: [Int] = []
    ) {
        self.id = id
        self.name = name
        self.habitDescription = habitDescription
        self.frequency = frequency
        self.remindAt = remindAt
        self.dailyInterval = dailyInterval
        self.weeklyInterval = weeklyInterval
        self.selectedWeekdays = selectedWeekdays
        self.monthlyInterval = monthlyInterval
        self.selectedDayOfMonth = selectedDayOfMonth
        self.customDays = customDays
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Habit Instance Model (for tracking completion)
struct HabitInstanceModel: Codable, Identifiable {
    let id: UUID
    let habitId: UUID
    let scheduledDate: Date
    var completedAt: Date?
    var skippedAt: Date?
    
    var isCompleted: Bool { completedAt != nil }
    var isSkipped: Bool { skippedAt != nil }
    
    init(
        id: UUID = UUID(),
        habitId: UUID,
        scheduledDate: Date,
        completedAt: Date? = nil,
        skippedAt: Date? = nil
    ) {
        self.id = id
        self.habitId = habitId
        self.scheduledDate = scheduledDate
        self.completedAt = completedAt
        self.skippedAt = skippedAt
    }
}

// MARK: - Medication Model
struct MedicationModel: Codable, Identifiable {
    let id: UUID
    var name: String
    var dosage: String
    var frequency: MedicationFrequency
    var reminderTimes: [Date]
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String = "",
        dosage: String = "",
        frequency: MedicationFrequency = .daily,
        reminderTimes: [Date] = []
    ) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.reminderTimes = reminderTimes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Enums (ya existen, pero los incluimos para completitud)
extension TaskPriority: Codable {}
extension HabitFrequency: Codable {}
extension MedicationFrequency: Codable {}