# Plan de Recuperación - meSync

Si Xcode sigue sin responder, sigue estos pasos:

## Opción 1: Crear proyecto nuevo (Recomendado)

1. Cierra Xcode completamente
2. En Xcode, crea un nuevo proyecto:
   - File > New > Project
   - iOS App
   - Nombre: meSync2
   - Interface: SwiftUI
   - Storage: None

3. Copia estos archivos al nuevo proyecto:
   - Styles/AppTheme.swift
   - Styles/ButtonStyles.swift
   - Styles/ViewExtensions.swift
   - Models/Models.swift
   - Services/DataManager.swift
   - Views/MinimalContentView.swift

4. En el nuevo proyecto, actualiza el archivo principal para usar MinimalContentView

## Opción 2: Usar Visual Studio Code

1. Instala Visual Studio Code
2. Instala la extensión "Swift" de Swift Server Work Group
3. Abre el proyecto en VS Code
4. Edita los archivos problemáticos

## Archivos a eliminar/comentar:
- HomeView.swift (tiene referencias a HabitFormView)
- ItemsListView.swift (puede tener problemas)
- ContentView.swift (usa HomeView)
- TaskFormView.swift (verificar)

## Estado actual:
- ✅ Modelos migrados a Codable
- ✅ DataManager implementado
- ❌ Vistas parcialmente migradas
- ❌ HabitFormView no migrado

El proyecto está en medio de una migración de SwiftData a JSON.