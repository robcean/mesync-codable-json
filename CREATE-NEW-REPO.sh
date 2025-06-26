#!/bin/bash

# Script para crear el nuevo repositorio mesync-json

echo "🚀 Creando nuevo repositorio mesync-json..."

# 1. Ir al directorio de proyectos
cd /Users/bjc/Documents/projects

# 2. Copiar el proyecto actual
cp -r mesync-002/meSync mesync-json

# 3. Entrar al nuevo proyecto
cd mesync-json

# 4. Limpiar git history
rm -rf .git

# 5. Inicializar nuevo repositorio
git init

# 6. Primer commit
git add .
git commit -m "Initial commit: meSync with JSON persistence

- Based on meSync v1.0 UI
- Migrating from SwiftData to Codable + JSON
- Preparing for Supabase integration"

# 7. Crear repositorio en GitHub (necesitas GitHub CLI)
# gh repo create mesync-json --public --source=. --remote=origin --push

echo "✅ Repositorio creado localmente"
echo "📝 Siguiente paso: Crear repo en GitHub y hacer push"
echo ""
echo "Comandos manuales si no tienes GitHub CLI:"
echo "1. Crear repositorio 'mesync-json' en GitHub.com"
echo "2. git remote add origin https://github.com/TU_USUARIO/mesync-json.git"
echo "3. git branch -M main"
echo "4. git push -u origin main"