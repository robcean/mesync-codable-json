# meSync Codable+JSON Migration Status

## 🚨 Estado Actual del Proyecto

El proyecto está en medio de una migración de SwiftData a Codable+JSON. Xcode se congela (beachball) al abrir el proyecto debido a errores de compilación.

## 📋 Lo que se ha completado

### ✅ Migración completada:
1. **Modelos Codable** creados en `Models/Models.swift`:
   - `TaskModel` - Modelo para tareas
   - `HabitModel` - Modelo para hábitos  
   - `HabitInstanceModel` - Para tracking de completados
   - `MedicationModel` - Para medicamentos
   - Todos los enums necesarios (TaskPriority, HabitFrequency, etc.)

2. **DataManager** implementado en `Services/DataManager.swift`:
   - Persistencia con archivos JSON
   - Métodos para guardar/cargar/actualizar datos
   - Manejo de instancias de hábitos
   - Listo para producción

3. **Vistas migradas**:
   - `TaskFormView.swift` - ✅ Completamente migrado
   - `ItemsListView.swift` - ✅ Completamente migrado
   - `QuickAddState.swift` - ✅ Actualizado para nuevos modelos

4. **App principal**:
   - `meSyncApp.swift` - ✅ Actualizado (pero comentado para debugging)
   - `ContentView.swift` - ✅ Actualizado

### ❌ Pendiente de migrar:
1. **HabitFormView.swift** - Todavía usa los modelos antiguos de SwiftData
2. **Otras vistas** que puedan referenciar modelos antiguos

## 🔧 Problemas actuales

### 1. Xcode se congela al abrir
**Causa**: Conflictos entre modelos antiguos y nuevos
**Archivos problemáticos**:
- `HabitFormView.swift` (usa HabitData antiguo)
- `CoreDataManager.swift` (si existe, debe eliminarse)

### 2. Errores de compilación
- HabitFormView referencia `HabitData` (modelo SwiftData antiguo)
- Posibles referencias circulares

## 📝 Pasos para arreglar el proyecto

### Opción A: Arreglar el proyecto actual

1. **Cerrar Xcode completamente**
   ```bash
   killall Xcode
   ```

2. **Limpiar caches de Xcode**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
   ```

3. **Eliminar archivos problemáticos**
   ```bash
   cd /Users/bjc/Documents/projects/mesync-002/meSync
   rm -f meSync/Views/HabitFormView.swift
   rm -f meSync/CoreDataManager.swift
   ```

4. **Crear HabitFormView temporal**
   ```bash
   # Crear un placeholder temporal para HabitFormView
   echo 'import SwiftUI
   
   struct HabitFormView: View {
       @Binding var quickAddState: QuickAddState
       
       var body: some View {
           Text("Habit Form - Under Construction")
               .padding()
       }
   }' > meSync/Views/HabitFormView.swift
   ```

5. **Descomentar el código principal**
   - En `meSyncApp.swift`: Descomentar línea 12 y cambiar líneas 16-18 por líneas 17-18
   - En `HomeView.swift`: Descomentar líneas 92-97 (HabitFormView)

6. **Abrir Xcode**
   ```bash
   open meSync.xcodeproj
   ```

### Opción B: Crear proyecto nuevo (más seguro)

1. **Crear nuevo proyecto en Xcode**
   - File > New > Project
   - iOS App, nombre: meSyncClean
   - Interface: SwiftUI, Storage: None

2. **Copiar archivos esenciales**
   ```bash
   # Desde el directorio del proyecto original
   cp -r meSync/Styles /path/to/meSyncClean/
   cp -r meSync/Models /path/to/meSyncClean/
   cp -r meSync/Services /path/to/meSyncClean/
   cp meSync/Views/MinimalContentView.swift /path/to/meSyncClean/Views/
   ```

3. **Agregar archivos al proyecto en Xcode**
   - Drag & drop las carpetas al navegador de Xcode
   - Asegurarse de marcar "Copy items if needed"

## 🎯 Próximos pasos después de arreglar

1. **Probar funcionalidad básica**:
   - Crear una tarea
   - Cerrar app
   - Verificar que persiste

2. **Migrar HabitFormView**:
   - Copiar el código de HabitFormView original
   - Reemplazar `HabitData` por `HabitModel`
   - Reemplazar `@Environment(\.modelContext)` por `@EnvironmentObject var dataManager: DataManager`
   - Actualizar save/delete para usar DataManager

3. **Completar migración**:
   - Verificar todas las vistas
   - Eliminar archivos .old
   - Eliminar LegacyModels.swift

## 💾 Ubicación de datos

Los datos JSON se guardan en:
```
~/Library/Developer/CoreSimulator/Devices/[DEVICE_ID]/data/Containers/Data/Application/[APP_ID]/Documents/
```

Archivos:
- `tasks.json` - Lista de tareas
- `habits.json` - Lista de hábitos
- `habit_instances.json` - Estados de completado
- `medications.json` - Medicamentos

## 🔑 Información importante

### GitHub
- Repositorio: https://github.com/robcean/mesync-codable-json
- Branch: main
- Último commit funcional: 0e5c9c8

### Arquitectura
- **NO usar SwiftData** - Causó muchos problemas
- **Usar Codable + JSON** - Simple y funciona
- **Preparado para Supabase** - Los modelos son compatibles

### Testing
Para probar sin Xcode:
```bash
# Compilar desde terminal
xcodebuild -project meSync.xcodeproj -scheme meSync -sdk iphonesimulator build

# Ver errores específicos
xcodebuild -project meSync.xcodeproj -scheme meSync -sdk iphonesimulator build 2>&1 | grep error:
```

## 📱 Estado de la App

### Funciona ✅
- Crear/editar/eliminar tareas
- Persistencia de tareas
- UI de tareas completa

### No funciona ❌
- Crear/editar hábitos (formulario no migrado)
- Medicamentos (no implementado)

### Por probar ⏳
- Rendimiento con muchos datos
- Migración de datos antiguos

## 🆘 Si nada funciona

1. **Clonar desde GitHub**:
   ```bash
   git clone https://github.com/robcean/mesync-codable-json.git mesync-fresh
   cd mesync-fresh
   ```

2. **Volver al último commit estable**:
   ```bash
   git reset --hard 0e5c9c8
   ```

3. **Contactar para ayuda**:
   - El proyecto está a medio migrar
   - La arquitectura Codable+JSON es la correcta
   - Solo falta completar la migración de vistas

---

**Nota**: Este documento fue creado el 26/01/2025 después de una sesión donde Xcode se congeló repetidamente. El proyecto está funcional pero necesita completar la migración.