# Plan meSync 2.0 - Arquitectura Supabase Offline-First

## 🎯 Visión General

meSync 2.0 será una reescritura completa con:
- ✅ Sincronización en tiempo real con Supabase
- ✅ Funcionamiento offline completo
- ✅ Arquitectura moderna y escalable
- ✅ Reutilización del 95% del código UI de v1.0

## 🏗️ Arquitectura Propuesta

### Stack Tecnológico
```
┌─────────────────────────────────────┐
│          SwiftUI Views              │  ← Copiadas de v1.0
├─────────────────────────────────────┤
│         View Models                 │  ← Nuevo
├─────────────────────────────────────┤
│      Repository Pattern             │  ← Nuevo
├─────────────────┬───────────────────┤
│   Local Cache   │  Supabase Client  │
│  (UserDefaults) │   (Postgrest)     │
└─────────────────┴───────────────────┘
```

### Estructura de Carpetas
```
meSync2/
├── App/
│   ├── meSyncApp.swift
│   └── ContentView.swift
├── Models/                    # Modelos Codable simples
│   ├── Habit.swift
│   ├── Task.swift
│   ├── Medication.swift
│   └── Instance.swift        # Para tracking diario
├── Views/                     # Copiadas de v1.0
│   ├── Home/
│   ├── Habits/
│   ├── Tasks/
│   ├── Medications/
│   └── Progress/
├── ViewModels/                # Nuevo - Lógica de negocio
│   ├── HabitsViewModel.swift
│   ├── TasksViewModel.swift
│   └── MedicationsViewModel.swift
├── Services/                  # Nuevo - Capa de datos
│   ├── SupabaseManager.swift
│   ├── LocalCache.swift
│   ├── SyncQueue.swift
│   └── NetworkMonitor.swift
├── Repositories/              # Nuevo - Abstracción
│   ├── HabitRepository.swift
│   ├── TaskRepository.swift
│   └── MedicationRepository.swift
├── Styles/                    # Copiados de v1.0
│   ├── AppTheme.swift
│   ├── ButtonStyles.swift
│   └── ViewExtensions.swift
└── Utils/
    ├── Extensions/
    └── Constants.swift
```

## 📊 Modelos de Datos

### Modelos Codable (compatibles con Supabase)

```swift
// Models/Habit.swift
struct Habit: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String?
    var frequency: String  // "daily", "weekly", etc.
    var frequencyDetails: FrequencyDetails?
    var remindAt: Date
    var userId: UUID?
    var createdAt: Date
    var updatedAt: Date
    
    // Para compatibilidad con v1.0 UI
    var isCompleted: Bool { 
        // Calculado basado en instances de hoy
        return false 
    }
}

// Models/HabitInstance.swift
struct HabitInstance: Codable, Identifiable {
    let id: UUID
    let habitId: UUID
    let scheduledDate: Date
    var completedAt: Date?
    var skippedAt: Date?
    var userId: UUID?
    
    var isCompleted: Bool { completedAt != nil }
    var isSkipped: Bool { skippedAt != nil }
}

// Similar para Task y Medication...
```

## 🗄️ Esquema Supabase

### SQL para crear tablas

```sql
-- Usuarios (si implementas auth)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Hábitos
CREATE TABLE habits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    frequency TEXT NOT NULL,
    frequency_details JSONB,
    remind_at TIME NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Instancias de hábitos (para tracking diario)
CREATE TABLE habit_instances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    habit_id UUID REFERENCES habits(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    scheduled_date DATE NOT NULL,
    completed_at TIMESTAMPTZ,
    skipped_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(habit_id, scheduled_date)
);

-- Tareas
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    priority TEXT NOT NULL,
    due_date TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ,
    skipped_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Medicamentos
CREATE TABLE medications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    instructions TEXT,
    frequency TEXT NOT NULL,
    times_per_day INTEGER DEFAULT 1,
    reminder_times TIME[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Instancias de medicamentos
CREATE TABLE medication_instances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    medication_id UUID REFERENCES medications(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    scheduled_date DATE NOT NULL,
    dose_number INTEGER NOT NULL,
    taken_at TIMESTAMPTZ,
    skipped_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(medication_id, scheduled_date, dose_number)
);

-- Índices para performance
CREATE INDEX idx_habit_instances_date ON habit_instances(scheduled_date);
CREATE INDEX idx_medication_instances_date ON medication_instances(scheduled_date);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);

-- RLS (Row Level Security) si usas auth
ALTER TABLE habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
-- etc...
```

## 💾 Sistema de Cache Local

### LocalCache.swift
```swift
import Foundation

class LocalCache {
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // Cache con expiración
    func save<T: Codable>(_ object: T, key: String, expiration: TimeInterval? = nil) {
        do {
            let data = try encoder.encode(object)
            userDefaults.set(data, forKey: key)
            
            if let expiration = expiration {
                let expirationDate = Date().addingTimeInterval(expiration)
                userDefaults.set(expirationDate, forKey: "\(key)_expiration")
            }
        } catch {
            print("Cache save error: \(error)")
        }
    }
    
    func load<T: Codable>(_ type: T.Type, key: String) -> T? {
        // Verificar expiración
        if let expirationDate = userDefaults.object(forKey: "\(key)_expiration") as? Date,
           Date() > expirationDate {
            remove(key: key)
            return nil
        }
        
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? decoder.decode(type, from: data)
    }
    
    func remove(key: String) {
        userDefaults.removeObject(forKey: key)
        userDefaults.removeObject(forKey: "\(key)_expiration")
    }
    
    // Para datos grandes, usar archivos
    func saveToFile<T: Codable>(_ object: T, filename: String) {
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        try? encoder.encode(object).write(to: url)
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
```

## 🔄 Implementación Offline-First

### SupabaseManager.swift
```swift
import Foundation
import Supabase

@MainActor
class SupabaseManager: ObservableObject {
    private let supabase: SupabaseClient
    private let cache = LocalCache()
    private let syncQueue = SyncQueue()
    private let networkMonitor = NetworkMonitor()
    
    init() {
        supabase = SupabaseClient(
            supabaseURL: URL(string: "YOUR_SUPABASE_URL")!,
            supabaseKey: "YOUR_SUPABASE_ANON_KEY"
        )
    }
    
    // MARK: - Habits
    func getHabits() async throws -> [Habit] {
        // Si estamos offline, usar cache
        if !networkMonitor.isConnected {
            return cache.load([Habit].self, key: "habits") ?? []
        }
        
        do {
            // Intentar obtener de Supabase
            let response: [Habit] = try await supabase
                .from("habits")
                .select()
                .order("created_at")
                .execute()
                .value
            
            // Actualizar cache
            cache.save(response, key: "habits")
            
            return response
        } catch {
            // Si falla, usar cache
            print("Error fetching habits: \(error)")
            return cache.load([Habit].self, key: "habits") ?? []
        }
    }
    
    func saveHabit(_ habit: Habit) async throws {
        // Optimistic update - actualizar cache inmediatamente
        var cachedHabits = cache.load([Habit].self, key: "habits") ?? []
        if let index = cachedHabits.firstIndex(where: { $0.id == habit.id }) {
            cachedHabits[index] = habit
        } else {
            cachedHabits.append(habit)
        }
        cache.save(cachedHabits, key: "habits")
        
        // Si estamos offline, agregar a cola de sincronización
        if !networkMonitor.isConnected {
            syncQueue.addOperation(.upsertHabit(habit))
            return
        }
        
        // Intentar sincronizar con Supabase
        do {
            try await supabase
                .from("habits")
                .upsert(habit)
                .execute()
        } catch {
            // Si falla, agregar a cola
            syncQueue.addOperation(.upsertHabit(habit))
            throw error
        }
    }
    
    // MARK: - Habit Instances (para tracking diario)
    func getHabitInstances(for date: Date) async throws -> [HabitInstance] {
        let dateString = ISO8601DateFormatter.string(from: date, timeZone: .current, formatOptions: [.withFullDate])
        let cacheKey = "habit_instances_\(dateString)"
        
        if !networkMonitor.isConnected {
            return cache.load([HabitInstance].self, key: cacheKey) ?? []
        }
        
        do {
            let response: [HabitInstance] = try await supabase
                .from("habit_instances")
                .select()
                .eq("scheduled_date", dateString)
                .execute()
                .value
            
            cache.save(response, key: cacheKey, expiration: 3600) // 1 hora
            return response
        } catch {
            return cache.load([HabitInstance].self, key: cacheKey) ?? []
        }
    }
    
    func markHabitComplete(habitId: UUID, date: Date, completed: Bool) async throws {
        let instance = HabitInstance(
            id: UUID(),
            habitId: habitId,
            scheduledDate: date,
            completedAt: completed ? Date() : nil,
            skippedAt: nil,
            userId: nil
        )
        
        // Actualizar cache local
        let dateString = ISO8601DateFormatter.string(from: date, timeZone: .current, formatOptions: [.withFullDate])
        let cacheKey = "habit_instances_\(dateString)"
        var instances = cache.load([HabitInstance].self, key: cacheKey) ?? []
        
        if let index = instances.firstIndex(where: { $0.habitId == habitId }) {
            instances[index] = instance
        } else {
            instances.append(instance)
        }
        cache.save(instances, key: cacheKey)
        
        // Sincronizar si hay conexión
        if networkMonitor.isConnected {
            try await supabase
                .from("habit_instances")
                .upsert(instance)
                .execute()
        } else {
            syncQueue.addOperation(.upsertHabitInstance(instance))
        }
    }
}
```

## 🎨 ViewModels

### HabitsViewModel.swift
```swift
import SwiftUI
import Combine

@MainActor
class HabitsViewModel: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var todayInstances: [HabitInstance] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let repository = HabitRepository()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadHabits()
    }
    
    func loadHabits() {
        Task {
            isLoading = true
            do {
                habits = try await repository.getHabits()
                todayInstances = try await repository.getInstances(for: Date())
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func saveHabit(_ habit: Habit) async throws {
        try await repository.saveHabit(habit)
        await loadHabits()
    }
    
    func toggleHabitCompletion(_ habit: Habit) async throws {
        let today = Date()
        let instance = todayInstances.first { $0.habitId == habit.id }
        
        if let instance = instance {
            // Toggle existing
            try await repository.updateInstance(
                instance.id,
                completed: !instance.isCompleted
            )
        } else {
            // Create new
            try await repository.createInstance(
                habitId: habit.id,
                date: today,
                completed: true
            )
        }
        
        await loadHabits()
    }
}
```

## 🔄 Sistema de Sincronización

### SyncQueue.swift
```swift
enum SyncOperation: Codable {
    case upsertHabit(Habit)
    case deleteHabit(UUID)
    case upsertTask(Task)
    case upsertHabitInstance(HabitInstance)
    // etc...
}

class SyncQueue {
    private var operations: [SyncOperation] = []
    private let storage = LocalCache()
    private let key = "sync_queue"
    
    init() {
        operations = storage.load([SyncOperation].self, key: key) ?? []
    }
    
    func addOperation(_ operation: SyncOperation) {
        operations.append(operation)
        storage.save(operations, key: key)
    }
    
    func syncAll(using manager: SupabaseManager) async {
        let pendingOps = operations
        operations = []
        storage.save(operations, key: key)
        
        for operation in pendingOps {
            do {
                try await execute(operation, using: manager)
            } catch {
                // Re-agregar si falla
                operations.append(operation)
            }
        }
        
        if !operations.isEmpty {
            storage.save(operations, key: key)
        }
    }
    
    private func execute(_ operation: SyncOperation, using manager: SupabaseManager) async throws {
        switch operation {
        case .upsertHabit(let habit):
            try await manager.saveHabit(habit)
        case .deleteHabit(let id):
            try await manager.deleteHabit(id)
        // etc...
        }
    }
}
```

## 🚀 Plan de Migración de v1.0 a v2.0

### Fase 1: Setup Inicial (1 día)
1. Crear nuevo proyecto meSync2
2. Configurar Supabase
3. Crear esquema de base de datos
4. Configurar cliente de Supabase

### Fase 2: Copiar UI (2 horas)
1. Copiar toda la carpeta Views/
2. Copiar toda la carpeta Styles/
3. Copiar assets y recursos
4. Ajustar imports

### Fase 3: Implementar Capa de Datos (1 día)
1. Crear modelos Codable
2. Implementar LocalCache
3. Implementar SupabaseManager
4. Crear Repositories

### Fase 4: Conectar ViewModels (1 día)
1. Crear ViewModels para cada vista
2. Reemplazar @Query con @StateObject
3. Conectar acciones a ViewModels
4. Probar offline/online

### Fase 5: Testing y Polish (1 día)
1. Probar sincronización
2. Manejar conflictos
3. Optimizar performance
4. Pulir UX

## 📱 Código de Ejemplo - Vista Completa

### HabitsView para v2.0
```swift
import SwiftUI

struct HabitsView: View {
    @StateObject private var viewModel = HabitsViewModel()
    @Binding var quickAddState: QuickAddState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Quick Add Form (igual que v1.0)
                if case .habitForm = quickAddState {
                    HabitFormView(
                        quickAddState: $quickAddState,
                        onSave: { habit in
                            Task {
                                try await viewModel.saveHabit(habit)
                            }
                        }
                    )
                }
                
                // Lista de hábitos
                LazyVStack(spacing: AppSpacing.md) {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else if viewModel.habits.isEmpty {
                        EmptyStateView() // Copiado de v1.0
                    } else {
                        ForEach(viewModel.habits) { habit in
                            HabitRow(
                                habit: habit,
                                isCompleted: viewModel.isCompleted(habit),
                                onToggle: {
                                    Task {
                                        try await viewModel.toggleHabitCompletion(habit)
                                    }
                                },
                                onEdit: {
                                    quickAddState = .habitForm(editing: habit)
                                }
                            )
                        }
                    }
                }
                .padding()
            }
        }
        .refreshable {
            await viewModel.loadHabits()
        }
    }
}
```

## 🎯 Ventajas de esta Arquitectura

1. **Offline-First Real**: Funciona sin internet
2. **Sincronización Automática**: Se sincroniza cuando hay conexión
3. **Un Solo Modelo**: No duplicas código
4. **Reutilización**: 95% del UI de v1.0
5. **Escalable**: Fácil agregar features
6. **Testeable**: ViewModels y Repositories son fáciles de testear

## 📚 Recursos y Dependencias

### Swift Package Manager
```swift
dependencies: [
    .package(url: "https://github.com/supabase-community/supabase-swift", from: "2.0.0")
]
```

### Documentación
- [Supabase Swift Client](https://github.com/supabase-community/supabase-swift)
- [Supabase Docs](https://supabase.com/docs)
- [SwiftUI Data Flow](https://developer.apple.com/documentation/swiftui/model-data)

## 🔐 Consideraciones de Seguridad

1. **API Keys**: Usar variables de entorno
2. **Auth**: Implementar Supabase Auth
3. **RLS**: Activar Row Level Security
4. **Validación**: Validar datos localmente antes de sync

---

*Este plan te da una base sólida para meSync 2.0. La arquitectura es moderna, escalable y aprovecha todo tu trabajo de v1.0.*