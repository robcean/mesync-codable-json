# Plan de Arreglo - meSync 1.0 con SwiftData

## 🎯 Objetivo: App 100% funcional en 2-3 horas

Este documento contiene el plan paso a paso para estabilizar meSync usando SwiftData simple.

## 📋 Lista de Tareas (2-3 horas total)

### Hora 1: Arreglar el Congelamiento (CRÍTICO)
- [ ] Debuggear el problema de QuickAddState
- [ ] Simplificar el flujo de guardado
- [ ] Probar que funcione guardar/editar/eliminar

### Hora 2: Estabilizar Persistencia
- [ ] Cambiar de memoria a persistencia real
- [ ] Verificar que los datos se guarden
- [ ] Limpiar código no usado

### Hora 3: Simplificar ProgressView
- [ ] Mostrar solo items del día actual
- [ ] Eliminar lógica de instancias
- [ ] Verificar que funcione el filtrado

## 🔧 Cambios Detallados

### 1. Arreglar Congelamiento en Formularios

**Problema**: La app se congela después de guardar
**Archivo**: `HabitFormView.swift`, `TaskFormView.swift`, `MedicationFormView.swift`

**Diagnóstico**:
```swift
// El problema está aquí:
withAnimation(.easeInOut(duration: 0.3)) {
    quickAddState.hide()  // Esto puede estar causando un ciclo
}
```

**Solución A - Eliminar animación**:
```swift
// En saveHabit(), saveTask(), saveMedication()
// Cambiar esto:
withAnimation(.easeInOut(duration: 0.3)) {
    quickAddState.hide()
}

// Por esto:
quickAddState = .hidden
```

**Solución B - Usar DispatchQueue**:
```swift
// Después de guardar:
DispatchQueue.main.async {
    quickAddState = .hidden
}
```

**Solución C - Revisar el Binding**:
```swift
// En HomeView, verificar que quickAddState no esté en un ciclo
// Agregar print statements para debuggear:
.onChange(of: quickAddState) { oldValue, newValue in
    print("QuickAddState cambió de \(oldValue) a \(newValue)")
}
```

### 2. Cambiar a Persistencia Real

**Archivo**: `meSyncApp.swift`

**Cambiar**:
```swift
let modelConfiguration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: true  // CAMBIAR ESTO
)
```

**Por**:
```swift
let modelConfiguration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false
)
```

**Si hay errores de migración**, usar:
```swift
// Opción 1: Borrar datos anteriores
let modelConfiguration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false,
    allowsSave: true
)

// Opción 2: Crear nuevo container
var sharedModelContainer: ModelContainer = {
    let schema = Schema([
        TaskData.self,
        HabitData.self,
        MedicationData.self
    ])
    
    // Intenta con una URL personalizada
    let url = URL.applicationSupportDirectory.appending(path: "meSync.sqlite")
    let modelConfiguration = ModelConfiguration(url: url)
    
    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        // Si falla, borra y recrea
        try? FileManager.default.removeItem(at: url)
        return try! ModelContainer(for: schema, configurations: [modelConfiguration])
    }
}()
```

### 3. Simplificar ItemsListView

**Archivo**: `ItemsListView.swift`

**Eliminar**:
- Toda referencia a `HabitInstance` y `MedicationInstance`
- Los métodos `generateHabitInstances()` y `generateMedicationInstances()`

**Simplificar allItems**:
```swift
private var allItems: [any ItemProtocol] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
    
    // Solo mostrar items de hoy
    let todayTasks = tasks.filter { task in
        task.dueDate >= today && task.dueDate < tomorrow
    }
    
    // Para hábitos y medicamentos, mostrarlos si su hora es hoy
    let todayHabits = habits.filter { habit in
        calendar.isDateInToday(habit.remindAt)
    }
    
    let todayMedications = medications.filter { medication in
        // Mostrar todos los medicamentos (el usuario decide si los tomó hoy)
        true
    }
    
    return (todayTasks + todayHabits + todayMedications)
        .sorted { $0.scheduledTime < $1.scheduledTime }
}
```

### 4. Simplificar ProgressView

**Archivo**: `ProgressView.swift`

**Cambiar generateHabitInstances**:
```swift
private func generateHabitInstances() -> [HabitData] {
    // Solo mostrar hábitos marcados como completados/skipped
    return habits.filter { $0.isCompleted || $0.isSkipped }
}

private func generateMedicationInstances() -> [MedicationData] {
    // Solo mostrar medicamentos marcados como completados/skipped
    return medications.filter { $0.isCompleted || $0.isSkipped }
}
```

**Simplificar filteredItems**:
```swift
private var filteredItems: [any ItemProtocol] {
    var items: [any ItemProtocol] = []
    
    // Agregar items según el filtro
    switch selectedFilter {
    case .all:
        items = tasks + habits + medications
    case .tasks:
        items = tasks
    case .habits:
        items = habits
    case .medications:
        items = medications
    }
    
    // Filtrar solo completados o skipped
    items = items.filter { $0.isCompleted || $0.isSkipped }
    
    // Aplicar búsqueda si hay texto
    if !searchText.isEmpty {
        let search = searchText.lowercased()
        items = items.filter {
            $0.name.lowercased().contains(search) ||
            $0.itemDescription.lowercased().contains(search)
        }
    }
    
    return items.sorted { $0.scheduledTime > $1.scheduledTime }
}
```

### 5. Limpiar Código No Usado

**Eliminar**:
1. Referencias a `InstanceStateManager` (ya eliminado)
2. Clases `HabitInstance` y `MedicationInstance` en ItemsListView
3. `HabitInstanceData` y `MedicationInstanceData` en QuickAddState.swift
4. El archivo `Item.swift` (no se usa)

**Comando para buscar referencias**:
```bash
# Buscar cualquier referencia sobrante
grep -r "Instance" --include="*.swift" .
grep -r "stateManager" --include="*.swift" .
```

## 🧪 Plan de Pruebas

### Después de cada cambio:
1. **Crear**: Un hábito, tarea y medicamento
2. **Editar**: Cambiar el nombre y guardar
3. **Marcar**: Como completado y skipped
4. **Eliminar**: Verificar que se borre
5. **Reiniciar**: Cerrar y abrir la app

### Prueba final:
1. Crear 3 items de cada tipo
2. Marcar algunos como completados
3. Ir a ProgressView y verificar que aparezcan
4. Cerrar la app completamente
5. Abrir y verificar que todo persista

## ⚡ Atajos y Tips

### Si el congelamiento persiste:
```swift
// Agregar más logs
print("Estado antes: \(quickAddState)")
quickAddState = .hidden
print("Estado después: \(quickAddState)")

// Verificar en la consola qué pasa
```

### Si SwiftData da errores:
```bash
# Borrar DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData

# En el simulador: Device > Erase All Content and Settings
```

### Para debuggear rápido:
```swift
// Agregar en ContentView
.onAppear {
    // Crear datos de prueba
    let task = TaskData(name: "Test Task", priority: .medium)
    modelContext.insert(task)
    try? modelContext.save()
}
```

## 📊 Resultado Esperado

Al terminar deberías tener:
- ✅ App que no se congela al guardar
- ✅ Datos que persisten entre sesiones
- ✅ ProgressView mostrando items completados
- ✅ CRUD completo funcionando
- ✅ Lista para usar diariamente

## 🚫 Lo que NO tendremos (OK para v1.0):
- ❌ Tracking por día específico
- ❌ Historial de 7 días en Progress
- ❌ Sincronización con backend
- ❌ Notificaciones

Esto es perfecto para v1.0. La complejidad adicional la agregamos en v2.0 con Supabase.

---

*Con este plan, en 2-3 horas tienes meSync 1.0 funcionando completamente.*