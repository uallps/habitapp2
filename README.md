# HabitApp

Aplicacion iOS/macOS para la gestion y seguimiento de habitos personales, desarrollada con SwiftUI y arquitectura modular de plugins.

## Autores

- **Bruno Ramirez Ledesma**
- **Alejandro Ortega Ramon**
- **Ilyas el Hamdi**

Universidad de Almeria - Ingenieria del Software - Lineas de Productos Software

---

## Descripcion

HabitApp es una aplicacion nativa que permite a los usuarios crear, gestionar y dar seguimiento a sus habitos diarios o semanales. La aplicacion implementa una **arquitectura de plugins** que permite activar o desactivar funcionalidades de forma modular.

### Funcionalidades principales

- Crear y editar habitos con nombre personalizado
- Configurar frecuencia (diaria o semanal con dias especificos)
- Marcar habitos como completados
- Archivar habitos que ya no se usan
- Soporte multiplataforma (iOS, iPadOS, macOS)

---

## Arquitectura

```
HabitApp/
├── Application/           # Punto de entrada y configuracion
│   ├── HabitApp.swift    # @main - Entry point
│   ├── AppConfig.swift   # Configuracion global y gestor de plugins
│   └── BuildFeatures.swift
│
├── Core/                  # Funcionalidad central
│   ├── Models/           # Habit, HabitFrequency
│   ├── ViewModels/       # HabitListViewModel
│   └── Views/            # HabitListView, HabitDetailView, HabitRowView
│
├── Features/              # Plugins modulares
│   ├── Categories/       # Categorizacion de habitos
│   ├── DailyNotes/       # Notas diarias por habito
│   ├── Statistics/       # Estadisticas y analisis
│   └── Settings/         # Configuracion de la app
│
└── Infraestructure/       # Servicios e infraestructura
    ├── Persistence/      # SwiftData storage providers
    └── Plugins/          # Sistema de plugins (Registry, Discovery)
```

### Sistema de Plugins

La aplicacion utiliza un sistema de plugins dinamico basado en protocolos:

| Protocolo | Descripcion |
|-----------|-------------|
| `FeaturePlugin` | Base para todos los plugins |
| `DataPlugin` | Plugins que manejan datos (notificados al eliminar habitos) |
| `ViewPlugin` | Plugins que proporcionan vistas (filas, detalles) |
| `TabPlugin` | Plugins que agregan pestanas a la navegacion |
| `HabitEventPlugin` | Plugins que reaccionan a cambios en habitos |

---

## Tecnologias

| Tecnologia | Uso |
|------------|-----|
| **Swift** | Lenguaje principal |
| **SwiftUI** | Framework de interfaz de usuario |
| **SwiftData** | Persistencia de datos (iOS 17+) |
| **Combine** | Programacion reactiva |

### Requisitos

- iOS 17.0+ / macOS 14.0+
- Xcode 15.0+
- Swift 5.9+

---

## Plugins Disponibles

### 1. Categories (Categorias)

Permite asignar categorias a los habitos para una mejor organizacion, con filtrado visual y badges coloridos.

**Funcionalidades:**
- Asignar categoria a cada habito
- Filtrar habitos por categoria desde la lista principal
- Badges visuales con colores distintivos por categoria
- Persistencia automatica de asignaciones

**Categorias predefinidas:**
| Categoria | Icono | Color | Descripcion |
|-----------|-------|-------|-------------|
| Bienestar | sparkles | Morado | Habitos de autocuidado |
| Salud | heart.fill | Rojo | Ejercicio, alimentacion |
| Aprendizaje | book.fill | Azul | Estudio, lectura |
| Productividad | bolt.fill | Naranja | Trabajo, tareas |
| Otro | square.grid.2x2 | Gris | Categoria general |

**Archivos:**
- `HabitCategoryAssignment.swift` - Modelo de asignacion + enum HabitCategory
- `HabitCategoryStorage.swift` - Persistencia con filtrado por categoria
- `HabitCategoryViewModel.swift` - Logica de presentacion
- `HabitCategoryRowView.swift` - Badge visual en lista (con color)
- `HabitCategoryDetailView.swift` - Selector de categoria
- `CategoryFilterBar.swift` - Barra de filtrado horizontal

### 2. Daily Notes (Notas Diarias)

Permite agregar notas textuales a los habitos por fecha.

### 3. Statistics (Estadisticas)

Dashboard completo con:
- Streaks (rachas de completacion)
- Calendario de actividad
- Graficos de progreso
- Analisis de tendencias

---

## Compilacion

### Variantes de Build

El proyecto soporta compilacion condicional mediante flags:

```swift
// Build Premium (todas las features)
#if PREMIUM

// Builds individuales por plugin
#if PLUGIN_CATEGORIES
#if PLUGIN_NOTES
#if PLUGIN_STATS
```

### Configuracion en Xcode

1. Abrir `HabitApp.xcodeproj`
2. Seleccionar el scheme deseado
3. Configurar Active Compilation Conditions en Build Settings
4. Build & Run

---

## Flujo de Datos

```
┌─────────────────────────────────────────────────┐
│              UI Layer (SwiftUI)                 │
│         HabitApp → TabView/NavigationStack      │
└────────────────────────┬────────────────────────┘
                         │
┌────────────────────────┴────────────────────────┐
│           Presentation (ViewModels)             │
│    HabitListViewModel, HabitCategoryViewModel   │
└────────────────────────┬────────────────────────┘
                         │
┌────────────────────────┴────────────────────────┐
│             Plugin System                       │
│      PluginRegistry → [Feature Plugins]         │
└────────────────────────┬────────────────────────┘
                         │
┌────────────────────────┴────────────────────────┐
│             Persistence Layer                   │
│    StorageProvider → SwiftData ModelContainer   │
└─────────────────────────────────────────────────┘
```

---

## Modelos de Datos

### Habit (Core)

```swift
@Model
class Habit {
    var id: UUID
    var name: String
    var frequency: HabitFrequency    // .daily | .weekly
    var isCompletedToday: Bool
    var lastCompletionDate: Date?
    var weeklyDays: [Int]            // Dias de la semana (1-7)
    var archivedAt: Date?
    var createdAt: Date
}
```

### HabitCategoryAssignment (Categories Plugin)

```swift
@Model
class HabitCategoryAssignment {
    var id: UUID
    var habitId: UUID
    var category: HabitCategory
}
```

---

## Contribuir

1. Fork del repositorio
2. Crear rama feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit cambios (`git commit -m 'Add nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abrir Pull Request

---

## Licencia

Proyecto academico - Universidad de Almeria 2024-2025
