//
//  Models.swift
//  meSync
//
//  Modelos Codable para persistencia JSON y futura integración con Supabase
//

import Foundation

// MARK: - Task Model
struct TaskModel: Codable, Identifiable, Equatable {
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
struct HabitModel: Codable, Identifiable, Equatable {
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
struct HabitInstanceModel: Codable, Identifiable, Equatable {
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

// MARK: - Medication Instance Model (for tracking completion)
struct MedicationInstanceModel: Codable, Identifiable, Equatable {
    let id: UUID
    let medicationId: UUID
    let scheduledDate: Date
    let doseNumber: Int
    var completedAt: Date?
    var skippedAt: Date?
    
    var isCompleted: Bool { completedAt != nil }
    var isSkipped: Bool { skippedAt != nil }
    
    init(
        id: UUID = UUID(),
        medicationId: UUID,
        scheduledDate: Date,
        doseNumber: Int,
        completedAt: Date? = nil,
        skippedAt: Date? = nil
    ) {
        self.id = id
        self.medicationId = medicationId
        self.scheduledDate = scheduledDate
        self.doseNumber = doseNumber
        self.completedAt = completedAt
        self.skippedAt = skippedAt
    }
}

// MARK: - Medication Model
struct MedicationModel: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var medicationDescription: String
    var instructions: String
    var timesPerDay: Int
    var reminderTimes: [Date]
    var unscheduledDoses: [Date]
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String = "",
        medicationDescription: String = "",
        instructions: String = "",
        timesPerDay: Int = 1,
        reminderTimes: [Date] = [Date()],
        unscheduledDoses: [Date] = []
    ) {
        self.id = id
        self.name = name
        self.medicationDescription = medicationDescription
        self.instructions = instructions
        self.timesPerDay = timesPerDay
        self.reminderTimes = reminderTimes.isEmpty ? [Date()] : reminderTimes
        self.unscheduledDoses = unscheduledDoses
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Supporting Enums
enum TaskPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
}

enum HabitFrequency: String, CaseIterable, Codable {
    case noRepetition = "No repetition"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case custom = "Custom"
}

