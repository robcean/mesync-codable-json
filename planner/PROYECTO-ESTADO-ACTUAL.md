# meSync - Estado Actual del Proyecto

## 📅 Última actualización: 26 de Junio 2025, 2:18 PM

## 🔴 Estado General: CRÍTICO - REGRESIÓN DE BUGS
La aplicación tiene problemas que creíamos resueltos y nuevos bugs críticos.

## 📝 Resumen Ejecutivo

meSync es una aplicación iOS para tracking de hábitos, tareas y medicamentos. Está desarrollada con SwiftUI y SwiftData. Actualmente la app está funcional pero con problemas de persistencia y congelamiento al guardar datos.

## 🏗️ Arquitectura Actual

### Stack Tecnológico
- **UI Framework**: SwiftUI
- **Persistencia**: SwiftData (con problemas)
- **Arquitectura**: MVVM parcial
- **Estado**: @State, @Binding, QuickAddState enum
- **Navegación**: Tab-based + Modal forms

### Estructura de Carpetas
```
meSync/
├── meSync/
│   ├── Styles/
│   │   ├── AppTheme.swift          ✅ Funcional - Define colores, espaciados, tipografía
│   │   ├── ButtonStyles.swift      ✅ Funcional - Estilos de botones reutilizables
│   │   ├── ViewExtensions.swift    ✅ Funcional - Extensiones útiles para vistas
│   │   └── QuickAddState.swift     ⚠️  Contiene modelos Y estado de navegación
│   ├── Views/
│   │   ├── HomeView.swift          ✅ Funcional - Vista principal con tabs
│   │   ├── HabitsView.swift        ✅ Funcional - Lista de hábitos
│   │   ├── TasksView.swift         ✅ Funcional - Lista de tareas
│   │   ├── MedicationsView.swift   ✅ Funcional - Lista de medicamentos
│   │   ├── ProgressView.swift      ⚠️  Funcional pero limitada
│   │   ├── ItemsListView.swift     ✅ Funcional - Lista unificada del día
│   │   ├── HabitFormView.swift     🔴 Se congela al guardar
│   │   ├── TaskFormView.swift      🔴 Se congela al guardar
│   │   └── MedicationFormView.swift 🔴 Se congela al guardar
│   ├── Managers/
│   │   └── [ELIMINADO] InstanceStateManager.swift
│   ├── ContentView.swift           ✅ Funcional - Vista raíz
│   ├── meSyncApp.swift            ⚠️  Usa almacenamiento en memoria
│   └── Item.swift                 ❌ No se usa (template code)
└── planner/                        📁 Nueva carpeta de documentación
```

## 🐛 Problemas Actuales

### 1. **REGRESIÓN: Congelamiento al Guardar Hábitos** 🔴 CRÍTICO
- **Síntoma**: La app se congela después de presionar "Save" en HabitFormView
- **Historia**: Este bug fue arreglado quitando .id() y transitions, pero REGRESÓ
- **Causa probable**: Algo cambió que reintrodujo el problema
- **Estado**: Bug que creíamos resuelto está de vuelta

### 2. **Pantalla Blanca con Persistencia Real** 🔴 CRÍTICO
- **Síntoma**: Al cambiar `isStoredInMemoryOnly: false`, la app muestra pantalla blanca
- **Causa**: Error de migración de SwiftData
- **Solución temporal**: Mantener en memoria (`true`)
- **Consecuencia**: Los datos se pierden al cerrar la app

### 3. **Estado Compartido en Medicaciones** ⚠️ IMPORTANTE
- **Síntoma**: Al marcar una medicación, se marcan TODAS las instancias
- **Ejemplo**: Marcar hoy también marca mañana y pasado mañana
- **Causa**: Estado guardado en objeto principal, no por instancia
- **Afecta**: Medicaciones y Hábitos

### 4. **ProgressView Sin Historial** ⚠️ MENOR
- **Estado**: Solo muestra estado actual, no historial por fechas
- **Decisión**: Aceptado como limitación de v1.0

## 📊 Modelos de Datos

### TaskData
```swift
@Model class TaskData {
    @Attribute(.unique) var id: UUID
    var name: String
    var taskDescription: String
    var priority: TaskPriority  // .low, .medium, .high, .urgent
    var dueDate: Date
    var isCompleted: Bool
    var isSkipped: Bool
}
```

### HabitData
```swift
@Model class HabitData {
    @Attribute(.unique) var id: UUID
    var name: String
    var habitDescription: String
    var frequency: HabitFrequency
    var remindAt: Date
    var isCompleted: Bool
    var isSkipped: Bool
    // + campos para repetición (daily, weekly, monthly, custom)
}
```

### MedicationData
```swift
@Model class MedicationData {
    @Attribute(.unique) var id: UUID
    var name: String
    var medicationDescription: String
    var instructions: String
    var frequency: MedicationFrequency
    var timesPerDay: Int
    var reminderTimes: [Date]      // Computed property
    var unscheduledDoses: [Date]   // Computed property
    var isCompleted: Bool
    var isSkipped: Bool
}
```

## 🎯 Funcionalidades Implementadas

### ✅ Completadas
1. **Sistema de Tabs**: Home, Habits, Tasks, Medications, Progress
2. **Quick Add**: Sistema de acordeón para agregar items rápidamente
3. **CRUD Básico**: Crear, leer, actualizar, eliminar (con bugs)
4. **Formularios Completos**: Todos los campos necesarios
5. **Diseño Responsivo**: Se adapta a diferentes tamaños
6. **Tema Consistente**: Colores, espaciados, tipografía

### ⚠️ Parcialmente Funcionales
1. **Guardar Datos**: Funciona pero congela la UI
2. **ProgressView**: Muestra datos pero sin historial real
3. **Repetición de Hábitos**: UI completa pero lógica simple

### ❌ No Implementadas
1. **Notificaciones**
2. **Sincronización con backend**
3. **Exportar datos**
4. **Configuración de usuario**
5. **Temas oscuro/claro**

## 💾 Historial de Cambios Importantes

### Sesión Anterior
1. Implementamos HabitsView, TasksView, ProgressView
2. Creamos InstanceStateManager para manejar estados
3. Agregamos tracking de timestamps
4. Múltiples bugs con el estado compartido

### Sesión Actual (26 Junio - Mañana)
1. **Problema inicial**: CoreData errors con Date arrays
2. **Intento 1**: Arreglar con @Attribute(.externalStorage) - falló
3. **Decisión**: Eliminar InstanceStateManager completamente
4. **Problema nuevo**: App muestra pantalla blanca
5. **Solución temporal**: Usar almacenamiento en memoria
6. **Fix aplicado**: Quitar .id() y transitions de HomeView - FUNCIONÓ
7. **Estado**: App funcionaba sin congelamiento

### Sesión Actual (26 Junio - Tarde)
1. **Fix anterior funcionando**: Complete/skip trabajaba para Tasks
2. **Problema**: Complete/skip no funcionaba para Habits/Medications
3. **Fix aplicado**: Actualizar originalHabit/originalMedication en instancias
4. **Nuevo problema**: ProgressView mostraba selector de fecha innecesario
5. **Fix**: Simplificar ProgressView sin selector de fecha
6. **CRÍTICO**: Intentar cambiar a persistencia real causó pantalla blanca
7. **CRÍTICO**: Después de revertir, el congelamiento de HabitForm REGRESÓ
8. **Estado actual**: App en memoria, se congela al guardar hábitos

## 🔧 Configuración Actual

### SwiftData Schema
```swift
let schema = Schema([
    TaskData.self,
    HabitData.self,
    MedicationData.self
])
let modelConfiguration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: true  // TEMPORAL!
)
```

### Dependencias
- iOS 17.0+
- Xcode 15+
- SwiftUI
- SwiftData
- No hay dependencias externas (CocoaPods/SPM)

## 📌 Notas Importantes

1. **QuickAddState.swift** contiene tanto el enum de navegación como TODOS los modelos
2. **Los formularios usan @FocusState** que puede estar relacionado con el congelamiento
3. **Se eliminó Item.swift** del schema pero el archivo aún existe
4. **InstanceStateManager fue eliminado** pero dejó código huérfano
5. **Los computed properties en MedicationData** usan JSON encoding para Date arrays

## 🚀 Próximos Pasos Recomendados

### Opción A: Investigar y Arreglar Regresión
1. **Comparar código actual con versión que funcionaba**
2. **Identificar qué causó la regresión del congelamiento**
3. **Aplicar fix permanente**
4. **Resolver migración de SwiftData para persistencia**

### Opción B: Mantener Simple para v1.0
1. **Aceptar limitaciones actuales**
2. **Usar solo en memoria**
3. **Documentar workarounds para usuarios**
4. **Enfocarse en migración a Supabase v2.0**

## 🔍 Pistas para Debug

### Congelamiento en HabitForm
- El fix anterior fue quitar `.id()` y `.transition()` de HomeView
- Verificar si algo los reintrodujo
- Revisar cambios en `quickAddState = .hidden`
- Posible problema con `@FocusState`

### Pantalla Blanca
- SwiftData no puede migrar schema existente
- Necesita borrar datos antiguos antes de cambiar configuración
- Considerar reset completo de simulador

---

*Este documento refleja el estado actual con todos los problemas conocidos. La app está en un estado crítico con regresión de bugs previamente arreglados.*