import Foundation

// MARK: - Persistence Manager con soporte para Supabase
class PersistenceManager {
    static let shared = PersistenceManager()
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let documentsDirectory: URL
    
    private init() {
        documentsDirectory = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
        
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Generic Save/Load
    func save<T: Codable>(_ object: T, to fileName: String) throws {
        let url = documentsDirectory.appendingPathComponent("\(fileName).json")
        let data = try encoder.encode(object)
        try data.write(to: url, options: .atomic)
        
        print("✅ Saved to: \(url.lastPathComponent)")
    }
    
    func load<T: Codable>(_ type: T.Type, from fileName: String) throws -> T {
        let url = documentsDirectory.appendingPathComponent("\(fileName).json")
        let data = try Data(contentsOf: url)
        return try decoder.decode(type, from: data)
    }
    
    func exists(_ fileName: String) -> Bool {
        let url = documentsDirectory.appendingPathComponent("\(fileName).json")
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    func delete(_ fileName: String) throws {
        let url = documentsDirectory.appendingPathComponent("\(fileName).json")
        try FileManager.default.removeItem(at: url)
    }
    
    // MARK: - Habits Specific
    func saveHabits(_ habits: [HabitModel]) {
        do {
            try save(habits, to: "habits")
        } catch {
            print("❌ Failed to save habits: \(error)")
        }
    }
    
    func loadHabits() -> [HabitModel] {
        do {
            return try load([HabitModel].self, from: "habits")
        } catch {
            print("⚠️ No habits found or error: \(error)")
            return []
        }
    }
    
    // MARK: - Tasks Specific
    func saveTasks(_ tasks: [TaskModel]) {
        do {
            try save(tasks, to: "tasks")
        } catch {
            print("❌ Failed to save tasks: \(error)")
        }
    }
    
    func loadTasks() -> [TaskModel] {
        do {
            return try load([TaskModel].self, from: "tasks")
        } catch {
            print("⚠️ No tasks found or error: \(error)")
            return []
        }
    }
    
    // MARK: - Sync Queue (para cuando vuelva la conexión)
    func savePendingSync<T: Codable>(_ items: [T], type: String) {
        do {
            try save(items, to: "pending_\(type)")
        } catch {
            print("❌ Failed to save pending sync: \(error)")
        }
    }
    
    func loadPendingSync<T: Codable>(_ type: T.Type, name: String) -> [T] {
        do {
            return try load([T].self, from: "pending_\(name)")
        } catch {
            return []
        }
    }
    
    // MARK: - Debug Helpers
    func printStorageLocation() {
        print("📁 Storage location: \(documentsDirectory.path)")
    }
    
    func listAllFiles() -> [String] {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: documentsDirectory,
                includingPropertiesForKeys: nil
            )
            return files.map { $0.lastPathComponent }
        } catch {
            return []
        }
    }
}

// MARK: - Modelos Codable (compatibles con Supabase)
struct HabitModel: Codable, Identifiable {
    let id: UUID
    var name: String
    var habitDescription: String
    var frequency: String
    var remindAt: Date
    var dailyInterval: Int
    var weeklyInterval: Int
    var selectedWeekdays: [Int]
    var monthlyInterval: Int
    var selectedDayOfMonth: Int
    var customDays: [Int]
    var createdAt: Date
    var updatedAt: Date
    
    // Para compatibilidad con Supabase
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case habitDescription = "description"
        case frequency
        case remindAt = "remind_at"
        case dailyInterval = "daily_interval"
        case weeklyInterval = "weekly_interval"
        case selectedWeekdays = "selected_weekdays"
        case monthlyInterval = "monthly_interval"
        case selectedDayOfMonth = "selected_day_of_month"
        case customDays = "custom_days"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        name: String = "",
        habitDescription: String = "",
        frequency: String = "none",
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

struct TaskModel: Codable, Identifiable {
    let id: UUID
    var name: String
    var taskDescription: String
    var priority: String
    var dueDate: Date
    var isCompleted: Bool
    var isSkipped: Bool
    var completedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case taskDescription = "description"
        case priority
        case dueDate = "due_date"
        case isCompleted = "is_completed"
        case isSkipped = "is_skipped"
        case completedAt = "completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        name: String = "",
        taskDescription: String = "",
        priority: String = "medium",
        dueDate: Date = Date(),
        isCompleted: Bool = false,
        isSkipped: Bool = false
    ) {
        self.id = id
        self.name = name
        self.taskDescription = taskDescription
        self.priority = priority
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.isSkipped = isSkipped
        self.completedAt = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}