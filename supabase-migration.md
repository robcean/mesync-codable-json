# Guía de Migración a Supabase con Real-Time

## Nivel de Dificultad: Medio (⭐⭐⭐☆☆)

## Ventajas de tu Arquitectura Actual

Tu implementación actual con JSON/Codable facilita mucho la migración:

1. **Modelos Codable listos** - `TaskModel`, `HabitModel`, `MedicationModel` ya son serializables
2. **DataManager centralizado** - Solo necesitas modificar los métodos de save/load
3. **Arquitectura limpia** - Las vistas no saben cómo se guardan los datos
4. **Separación de concerns** - La lógica de negocio está separada de la persistencia

## Pasos de Migración

### 1. Instalar Supabase Swift SDK

```swift
// En Package.swift o mediante Xcode
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
]
```

### 2. Configurar Base de Datos en Supabase

Crear las siguientes tablas en el dashboard de Supabase:

```sql
-- Tabla de Tareas
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    task_description TEXT,
    priority TEXT NOT NULL,
    due_date TIMESTAMPTZ NOT NULL,
    is_completed BOOLEAN DEFAULT false,
    is_skipped BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    skipped_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    user_id UUID REFERENCES auth.users(id)
);

-- Tabla de Hábitos
CREATE TABLE habits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    habit_description TEXT,
    frequency TEXT NOT NULL,
    remind_at TIMESTAMPTZ NOT NULL,
    daily_interval INTEGER DEFAULT 1,
    weekly_interval INTEGER DEFAULT 1,
    monthly_interval INTEGER DEFAULT 1,
    selected_weekdays INTEGER[],
    selected_day_of_month INTEGER,
    custom_days INTEGER[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    user_id UUID REFERENCES auth.users(id)
);

-- Tabla de Instancias de Hábitos
CREATE TABLE habit_instances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    habit_id UUID REFERENCES habits(id) ON DELETE CASCADE,
    scheduled_date DATE NOT NULL,
    completed_at TIMESTAMPTZ,
    skipped_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(habit_id, scheduled_date)
);

-- Tabla de Medicamentos
CREATE TABLE medications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    medication_description TEXT,
    instructions TEXT,
    times_per_day INTEGER NOT NULL,
    reminder_times TIMESTAMPTZ[],
    unscheduled_doses TIMESTAMPTZ[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    user_id UUID REFERENCES auth.users(id)
);

-- Tabla de Instancias de Medicamentos
CREATE TABLE medication_instances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    medication_id UUID REFERENCES medications(id) ON DELETE CASCADE,
    scheduled_date DATE NOT NULL,
    dose_number INTEGER NOT NULL,
    completed_at TIMESTAMPTZ,
    skipped_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(medication_id, scheduled_date, dose_number)
);

-- Habilitar Row Level Security
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE habit_instances ENABLE ROW LEVEL SECURITY;
ALTER TABLE medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE medication_instances ENABLE ROW LEVEL SECURITY;

-- Políticas de seguridad (usuarios solo ven sus propios datos)
CREATE POLICY "Users can CRUD their own tasks" ON tasks
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can CRUD their own habits" ON habits
    FOR ALL USING (auth.uid() = user_id);

-- Similar para las demás tablas...
```

### 3. Crear SupabaseManager

```swift
import Foundation
import Supabase

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    private var realtimeChannel: RealtimeChannel?
    
    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "YOUR_SUPABASE_PROJECT_URL")!,
            supabaseKey: "YOUR_SUPABASE_ANON_KEY"
        )
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }
    
    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password)
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    // MARK: - Real-time Setup
    
    func setupRealtimeListeners() {
        realtimeChannel = client.realtime.channel("db-changes")
        
        // Escuchar cambios en tareas
        realtimeChannel?
            .on(.postgres(
                .all,
                schema: "public",
                table: "tasks"
            )) { [weak self] payload in
                Task { @MainActor in
                    await self?.handleTaskChange(payload)
                }
            }
            
        // Escuchar cambios en hábitos
        realtimeChannel?
            .on(.postgres(
                .all,
                schema: "public",
                table: "habits"
            )) { [weak self] payload in
                Task { @MainActor in
                    await self?.handleHabitChange(payload)
                }
            }
            
        // Suscribirse al canal
        Task {
            try? await realtimeChannel?.subscribe()
        }
    }
    
    private func handleTaskChange(_ payload: PostgresChangePayload) async {
        // Actualizar DataManager con los cambios
        await DataManager.shared.refreshTasks()
    }
    
    private func handleHabitChange(_ payload: PostgresChangePayload) async {
        // Actualizar DataManager con los cambios
        await DataManager.shared.refreshHabits()
    }
}
```

### 4. Modificar DataManager para Supabase

```swift
import Foundation
import SwiftUI
import Supabase

@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var tasks: [TaskModel] = []
    @Published var habits: [HabitModel] = []
    @Published var habitInstances: [HabitInstanceModel] = []
    @Published var medications: [MedicationModel] = []
    @Published var medicationInstances: [MedicationInstanceModel] = []
    
    private let supabase = SupabaseManager.shared.client
    private var useOfflineMode = false
    
    // MARK: - Hybrid Save Methods (Local + Cloud)
    
    func saveTask(_ task: TaskModel) async {
        // Actualizar localmente primero (respuesta inmediata)
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        } else {
            tasks.append(task)
        }
        
        // Guardar localmente para offline support
        saveToLocalJSON(tasks, fileName: "tasks")
        
        // Sincronizar con Supabase
        do {
            let response = try await supabase.database
                .from("tasks")
                .upsert(task)
                .execute()
            
            print("✅ Task synced to Supabase")
        } catch {
            print("⚠️ Failed to sync to Supabase: \(error)")
            // Marcar para sincronización posterior
            markForSync(task)
        }
    }
    
    // MARK: - Load Methods with Offline Support
    
    func loadAllData() async {
        // Cargar datos locales primero (respuesta inmediata)
        loadLocalData()
        
        // Luego sincronizar con Supabase
        await syncWithSupabase()
    }
    
    private func syncWithSupabase() async {
        do {
            // Cargar tareas
            let tasksResponse: [TaskModel] = try await supabase.database
                .from("tasks")
                .select()
                .execute()
                .value
            
            // Cargar hábitos
            let habitsResponse: [HabitModel] = try await supabase.database
                .from("habits")
                .select()
                .execute()
                .value
            
            // Actualizar datos locales con los de la nube
            await MainActor.run {
                self.tasks = tasksResponse
                self.habits = habitsResponse
                
                // Guardar localmente
                saveToLocalJSON(tasks, fileName: "tasks")
                saveToLocalJSON(habits, fileName: "habits")
            }
            
        } catch {
            print("⚠️ Failed to sync with Supabase: \(error)")
            useOfflineMode = true
        }
    }
    
    // MARK: - Sync Queue for Offline Changes
    
    private func markForSync<T: Codable & Identifiable>(_ item: T) {
        // Implementar cola de sincronización para cuando vuelva la conexión
        var syncQueue = loadSyncQueue()
        syncQueue.append(SyncItem(type: String(describing: T.self), id: item.id, data: item))
        saveSyncQueue(syncQueue)
    }
    
    func processSyncQueue() async {
        let syncQueue = loadSyncQueue()
        
        for item in syncQueue {
            // Procesar cada item pendiente de sincronización
            // ...
        }
    }
}

// MARK: - Sync Queue Model
struct SyncItem: Codable {
    let type: String
    let id: Identifiable.ID
    let data: Codable
    let timestamp: Date = Date()
}
```

### 5. Configurar Real-time en la App

```swift
// En meSyncApp.swift
import SwiftUI
import Supabase

@main
struct meSyncApp: App {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var supabaseManager = SupabaseManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(supabaseManager)
                .task {
                    // Configurar real-time al iniciar
                    supabaseManager.setupRealtimeListeners()
                    
                    // Cargar datos
                    await dataManager.loadAllData()
                }
        }
    }
}
```

### 6. Agregar Vista de Autenticación

```swift
struct AuthView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Text(isSignUp ? "Create Account" : "Sign In")
                .primaryTitleStyle()
            
            VStack(spacing: AppSpacing.md) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: authenticate) {
                Text(isSignUp ? "Sign Up" : "Sign In")
                    .frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
            
            Button(action: { isSignUp.toggle() }) {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.caption)
            }
            .textButtonStyle()
        }
        .padding()
    }
    
    private func authenticate() {
        Task {
            do {
                if isSignUp {
                    try await supabaseManager.signUp(email: email, password: password)
                } else {
                    try await supabaseManager.signIn(email: email, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
```

## Ventajas de Usar Supabase

1. **Sincronización Automática**: Los cambios se sincronizan entre todos los dispositivos
2. **Colaboración Real-time**: Múltiples usuarios pueden ver cambios instantáneamente
3. **Backup en la Nube**: Datos seguros y respaldados automáticamente
4. **Autenticación Incluida**: Sistema de usuarios sin código adicional
5. **Offline Support**: Mantén funcionalidad sin conexión
6. **Escalabilidad**: Crece con tu base de usuarios sin cambiar código

## Consideraciones Importantes

### 1. Manejo de Conflictos
```swift
// Estrategia: Last Write Wins con timestamps
func resolveConflict(local: TaskModel, remote: TaskModel) -> TaskModel {
    return local.updatedAt > remote.updatedAt ? local : remote
}
```

### 2. Seguridad
- Usa Row Level Security (RLS) en todas las tablas
- Nunca expongas las keys de Supabase en el código
- Implementa validación tanto en cliente como servidor

### 3. Optimización
- Implementa paginación para listas largas
- Usa debouncing para actualizaciones frecuentes
- Cachea datos localmente para respuesta rápida

## Tiempo Estimado de Implementación

- **Configuración básica**: 2-3 horas
- **Migración de datos existentes**: 4-6 horas
- **Real-time completo**: 1-2 días
- **Autenticación y seguridad**: 4-6 horas
- **Testing y pulido**: 1-2 días

**Total**: 3-5 días de trabajo para una migración completa y robusta

## Próximos Pasos

1. Crear cuenta en Supabase
2. Configurar el proyecto y obtener las keys
3. Implementar autenticación básica
4. Migrar un modelo a la vez (empezar con Tasks)
5. Agregar real-time progresivamente
6. Implementar sincronización offline

## Recursos Útiles

- [Documentación de Supabase Swift](https://github.com/supabase/supabase-swift)
- [Guía de Real-time](https://supabase.com/docs/guides/realtime)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [Mejores Prácticas](https://supabase.com/docs/guides/best-practices)