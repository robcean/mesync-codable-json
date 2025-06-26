# Decisión de Arquitectura: Persistencia en meSync

## Contexto
Necesitamos elegir una solución de persistencia que:
1. Funcione offline
2. Sea estable y confiable
3. Permita futura sincronización con Supabase
4. No cause pantallas blancas o crashes

## Opciones Evaluadas

### 1. SwiftData ❌
- **Pros**: Moderno, integrado con SwiftUI
- **Contras**: Inestable, bugs, pantallas blancas
- **Veredicto**: NO USAR hasta que madure

### 2. Core Data ⚠️
- **Pros**: Maduro, robusto, excelente para datos locales
- **Contras**: Incompatible con Supabase realtime
- **Veredicto**: Bueno para v1.0, problemático para v2.0

### 3. Codable + JSON Files ✅
- **Pros**: 
  - Simple y predecible
  - Compatible con Supabase
  - Fácil de debuggear
  - Sin migraciones complejas
- **Contras**: 
  - Menos eficiente que Core Data
  - Búsquedas más lentas
- **Veredicto**: MEJOR OPCIÓN para tu caso

## Recomendación Final

### Para meSync v1.0 (Ahora):
```swift
// Usar Codable con almacenamiento en archivos JSON
struct PersistenceManager {
    private let documentsDirectory = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)
        .first!
    
    func save<T: Codable>(_ object: T, to fileName: String) {
        let url = documentsDirectory.appendingPathComponent("\(fileName).json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(object)
            try data.write(to: url)
        } catch {
            print("Failed to save \(fileName): \(error)")
        }
    }
    
    func load<T: Codable>(_ type: T.Type, from fileName: String) -> T? {
        let url = documentsDirectory.appendingPathComponent("\(fileName).json")
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to load \(fileName): \(error)")
            return nil
        }
    }
}
```

### Ventajas de esta aproximación:
1. **Funciona YA** - Sin problemas de SwiftData
2. **Compatible con Supabase** - Mismos modelos Codable
3. **Debugging fácil** - Puedes ver los JSON
4. **Sin migraciones** - Solo agregar campos opcionales
5. **Portable** - Funciona en cualquier plataforma

### Para meSync v2.0 (Futuro):
- Los mismos modelos Codable
- Agregar capa de sincronización con Supabase
- Cache local sigue siendo JSON
- Realtime funcionará perfectamente

## Implementación Paso a Paso

1. Convertir modelos a Codable puro (quitar @Model)
2. Implementar PersistenceManager
3. Actualizar vistas para usar @StateObject
4. Testear guardado/carga
5. Preparar para Supabase manteniendo Codable

Esta es la ruta más segura y práctica para tu aplicación.