//
//  QuickAddStateMigrated.swift
//  meSync
//
//  Estado centralizado para el flujo Quick Add (versión migrada)
//

import Foundation

// MARK: - Quick Add State
enum QuickAddState: Equatable {
    case hidden
    case accordion
    case taskForm(editingTask: TaskModel? = nil)
    case habitForm(editingHabit: HabitModel? = nil)
    case medicationForm(editingMedication: MedicationModel? = nil)
    
    // MARK: - Computed Properties
    
    /// Indica si algún formulario está visible
    var isFormVisible: Bool {
        switch self {
        case .taskForm, .habitForm, .medicationForm:
            return true
        case .hidden, .accordion:
            return false
        }
    }
    
    /// Indica si el acordeón está visible
    var isAccordionVisible: Bool {
        if case .accordion = self {
            return true
        }
        return false
    }
    
    /// Indica si está en modo edición
    var isEditing: Bool {
        switch self {
        case .taskForm(let task):
            return task != nil
        case .habitForm(let habit):
            return habit != nil
        case .medicationForm(let medication):
            return medication != nil
        case .hidden, .accordion:
            return false
        }
    }
    
    /// Título del formulario actual
    var formTitle: String {
        switch self {
        case .taskForm(let task):
            return task != nil ? "Editing Task" : "Creating Task"
        case .habitForm(let habit):
            return habit != nil ? "Editing Habit" : "Creating Habit"
        case .medicationForm(let medication):
            return medication != nil ? "Editing Medication" : "Creating Medication"
        case .hidden, .accordion:
            return ""
        }
    }
    
    // MARK: - Transition Methods
    
    /// Transiciones válidas desde el estado actual
    func canTransitionTo(_ newState: QuickAddState) -> Bool {
        switch (self, newState) {
        case (.hidden, .accordion),
             (.accordion, .hidden),
             (.accordion, .taskForm),
             (.accordion, .habitForm),
             (.accordion, .medicationForm),
             (.taskForm, .accordion),
             (.habitForm, .accordion),
             (.medicationForm, .accordion),
             (.taskForm, .hidden),
             (.habitForm, .hidden),
             (.medicationForm, .hidden):
            return true
        default:
            return false
        }
    }
    
    /// Cancela el estado actual y vuelve al anterior apropiado
    mutating func cancel() {
        switch self {
        case .taskForm, .habitForm, .medicationForm:
            self = .accordion
        case .accordion:
            self = .hidden
        case .hidden:
            break // Ya está oculto
        }
    }
    
    /// Oculta todo el Quick Add
    mutating func hide() {
        self = .hidden
    }
}