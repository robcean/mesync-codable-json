#!/bin/bash

# Script para arreglar el proyecto meSync después del freeze de Xcode
# Ejecutar con: bash fix-xcode-project.sh

echo "🔧 Arreglando proyecto meSync..."

# 1. Cerrar Xcode
echo "1️⃣ Cerrando Xcode..."
killall Xcode 2>/dev/null || echo "   Xcode no estaba ejecutándose"

# 2. Limpiar caches
echo "2️⃣ Limpiando caches de Xcode..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*

# 3. Eliminar archivos problemáticos
echo "3️⃣ Eliminando archivos problemáticos..."
rm -f meSync/Views/HabitFormView.swift
rm -f meSync/CoreDataManager.swift
rm -f meSync/Models/LegacyModels.swift

# 4. Crear HabitFormView temporal
echo "4️⃣ Creando HabitFormView temporal..."
cat > meSync/Views/HabitFormView.swift << 'EOF'
import SwiftUI

struct HabitFormView: View {
    @Binding var quickAddState: QuickAddState
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Habit Form")
                .font(.largeTitle)
                .padding()
            
            Text("🚧 Under Construction 🚧")
                .font(.title2)
                .foregroundColor(.orange)
            
            Text("Esta vista necesita ser migrada de SwiftData a Codable")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Cerrar") {
                withAnimation {
                    quickAddState = .hidden
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    @Previewable @State var quickAddState: QuickAddState = .habitForm()
    HabitFormView(quickAddState: $quickAddState)
        .environmentObject(DataManager.shared)
}
EOF

# 5. Arreglar meSyncApp.swift
echo "5️⃣ Actualizando meSyncApp.swift..."
cat > meSync/meSyncApp.swift << 'EOF'
//
//  meSyncApp.swift
//  meSync
//
//  Created by Brandon Cean on 6/13/25.
//

import SwiftUI

@main
struct meSyncApp: App {
    @StateObject private var dataManager = DataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
    }
}
EOF

# 6. Verificar estado
echo "6️⃣ Verificando archivos..."
echo "   Archivos en Models/:"
ls -la meSync/Models/
echo ""
echo "   Archivos en Services/:"
ls -la meSync/Services/
echo ""
echo "   Archivos en Views/:"
ls -la meSync/Views/

echo ""
echo "✅ Proceso completado!"
echo ""
echo "📝 Próximos pasos:"
echo "   1. Abre Xcode: open meSync.xcodeproj"
echo "   2. Espera a que termine de indexar"
echo "   3. Presiona Cmd+B para compilar"
echo "   4. Si funciona, presiona Cmd+R para ejecutar"
echo ""
echo "⚠️  Nota: HabitFormView es temporal y necesita ser migrado"