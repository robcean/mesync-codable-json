import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "meSync")
        
        // Configurar para migraciones automáticas
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        container.loadPersistentStores { _, error in
            if let error = error {
                // En producción, manejar el error apropiadamente
                fatalError("Core Data failed to load: \(error)")
            }
        }
        
        // Configurar para mejor rendimiento
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    // Contexto principal para UI
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // Guardar cambios
    func save() {
        guard viewContext.hasChanges else { return }
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    // Contexto para operaciones en background
    func backgroundContext() -> NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }
}

// MARK: - Fetch Helpers
extension CoreDataManager {
    func fetchHabits() -> [HabitEntity] {
        let request: NSFetchRequest<HabitEntity> = HabitEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching habits: \(error)")
            return []
        }
    }
    
    func fetchTasks(for date: Date? = nil) -> [TaskEntity] {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        
        if let date = date {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            request.predicate = NSPredicate(
                format: "dueDate >= %@ AND dueDate < %@", 
                startOfDay as NSDate, 
                endOfDay as NSDate
            )
        }
        
        request.sortDescriptors = [
            NSSortDescriptor(key: "priority", ascending: false),
            NSSortDescriptor(key: "dueDate", ascending: true)
        ]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching tasks: \(error)")
            return []
        }
    }
    
    func fetchHabitInstances(for habit: HabitEntity, date: Date) -> HabitInstanceEntity? {
        let request: NSFetchRequest<HabitInstanceEntity> = HabitInstanceEntity.fetchRequest()
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(
            format: "habit == %@ AND date >= %@ AND date < %@",
            habit,
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        request.fetchLimit = 1
        
        do {
            return try viewContext.fetch(request).first
        } catch {
            print("Error fetching habit instance: \(error)")
            return nil
        }
    }
}

// MARK: - Migration Support
extension CoreDataManager {
    func performLightweightMigration() {
        // Core Data maneja migraciones ligeras automáticamente
        // Para migraciones complejas, crear NSMappingModel
    }
    
    func deleteAllData() {
        // Útil para desarrollo/testing
        let entities = persistentContainer.managedObjectModel.entities
        
        for entity in entities {
            guard let name = entity.name else { continue }
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try viewContext.execute(deleteRequest)
                try viewContext.save()
            } catch {
                print("Error deleting \(name): \(error)")
            }
        }
    }
}