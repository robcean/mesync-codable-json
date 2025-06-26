# Limitaciones de meSync v1.0

## ⚠️ AVISO IMPORTANTE
La versión 1.0 tiene limitaciones significativas y bugs conocidos. Esta documentación explica cómo trabajar con estas limitaciones.

## 🔴 Bugs Críticos Actuales

### 1. Congelamiento al Guardar Hábitos
- **Problema**: La app se congela al guardar un hábito nuevo
- **Estado**: Bug que fue arreglado pero regresó
- **Workaround**: Forzar cierre de la app y reiniciar

### 2. Sin Persistencia Real
- **Problema**: Usando almacenamiento en memoria temporal
- **Consecuencia**: TODOS los datos se pierden al cerrar la app
- **Workaround**: No cerrar la app durante una sesión de uso

## ⚠️ Limitaciones de Diseño

### Estado Compartido en Medicaciones
- **Limitación**: Cuando marcas una medicación como completada o saltada, se marcan TODAS las instancias (hoy, mañana, pasado mañana) al mismo tiempo
- **Razón**: El estado se guarda en el objeto MedicationData principal, no por instancia/día
- **Workaround**: Usar solo para marcar medicaciones del día actual
- **Ejemplo**: Si marcas "Aspirina" como completada hoy, también aparecerá completada mañana

### Estado Compartido en Hábitos
- **Limitación**: Similar a medicaciones, el estado se comparte entre todas las instancias del hábito
- **Workaround**: Marcar solo hábitos del día actual

### Progress Sin Historial
- **Limitación**: Solo muestra el estado actual, no un historial por días
- **Razón**: Sin un modelo de instancias persistentes, no podemos trackear el historial
- **Lo que ves**: Items actualmente marcados como completados/saltados
- **Lo que NO ves**: Cuándo fueron completados o historial de días anteriores

## 📱 Cómo Usar v1.0 con Sus Limitaciones

### Uso Diario Recomendado
1. **NO cierres la app** - Los datos se perderán
2. **Marca items solo del día actual** - No intentes marcar días futuros
3. **Si se congela**: Forzar cierre y reiniciar (perderás datos)
4. **Tasks funcionan mejor** - Tienen menos problemas que Habits/Medications

### Lo que SÍ Funciona
- Crear y editar Tasks ✅
- Marcar Tasks como completados ✅
- Ver items en HomeView ✅
- Navegación entre tabs ✅

### Lo que NO Funciona Bien
- Guardar Hábitos (se congela) ❌
- Persistencia entre sesiones ❌
- Estados independientes por día ❌
- Historial en Progress ❌

## 🚀 Plan para v2.0

### Arquitectura Nueva
- Base de datos Supabase
- Sincronización offline-first
- Estados independientes por instancia

### Soluciones a Implementar
1. **Tabla `habit_instances`**
   - ID único por hábito + fecha
   - Estado independiente por día
   - Historial completo

2. **Tabla `medication_instances`**
   - ID único por medicación + dosis + fecha
   - Tracking de dosis individuales
   - Horarios específicos

3. **Persistencia Real**
   - Datos guardados permanentemente
   - Sincronización entre dispositivos
   - Backup automático

## 💡 Recomendación

Dado el estado actual con bugs críticos y sin persistencia, recomendamos:

1. **Para Testing**: Usar la app sabiendo que los datos se perderán
2. **Para Uso Real**: Esperar a v2.0 con Supabase
3. **Para Desarrollo**: Enfocarse en migrar a Supabase en lugar de arreglar v1.0

---

*v1.0 es principalmente una prueba de concepto. Las limitaciones son significativas y los bugs críticos hacen que no sea apta para uso diario.*