# Plan de Migración: SwiftData → Codable + JSON

## Objetivo
Migrar la app actual de SwiftData (in-memory) a Codable + JSON manteniendo toda la UI existente.

## Ventajas de este approach
- ✅ Mantenemos el 100% de la UI (que ya funciona bien)
- ✅ Migración incremental (sin romper la app)
- ✅ Persistencia real en 1-2 días
- ✅ Preparados para Supabase
- ✅ Sin pantallas blancas ni bugs

## Paso 1: Crear nuevos modelos Codable (30 min)
```swift
// Reemplazar @Model por struct Codable
struct TaskModel: Codable { ... }
struct HabitModel: Codable { ... }
```

## Paso 2: Crear DataManager (1 hora)
```swift
class DataManager: ObservableObject {
    @Published var tasks: [TaskModel] = []
    @Published var habits: [HabitModel] = []
    
    func loadData() { ... }
    func saveData() { ... }
}
```

## Paso 3: Migrar vistas una por una (3-4 horas)
- Reemplazar @Query con @StateObject
- Cambiar TaskData → TaskModel
- Actualizar acciones para usar DataManager

## Paso 4: Testing exhaustivo (2 horas)
- Crear/editar/eliminar items
- Verificar persistencia
- Probar edge cases

## Paso 5: Limpieza (1 hora)
- Eliminar archivos SwiftData
- Actualizar documentación
- Commit final

## Archivos a modificar
1. QuickAddState.swift → Modelos Codable
2. meSyncApp.swift → Eliminar SwiftData
3. Vistas principales → Usar DataManager
4. Crear Services/DataManager.swift

## Resultado final
- App estable con persistencia real
- Misma UI que ya funciona
- Lista para Supabase
- Sin bugs de SwiftData