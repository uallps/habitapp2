# Implementacion de Estadisticas (Plugin)

## Objetivo
Se implemento un modulo de Estadisticas (Recaps) como plugin desacoplado para la app de habitos. La pestaña "Estadisticas" muestra un overview con selector de fecha, resumen, tarjetas de recap y una visualizacion rapida, y cada recap abre su detalle diario/semanal/mensual/anual.

## Arquitectura y desacoplamiento
- El plugin consume datos a traves de **protocolos** (`HabitStatsDataSource`, `CompletionStatsDataSource`) definidos en `HabitApp/Infraestructure/Statistics/StatisticsContracts.swift`.
- El core inyecta dependencias via `StatisticsDependencies` en `AppConfig`, usando **adaptadores** (`CoreHabitStatsAdapter`, `CoreCompletionStatsAdapter`) que traducen el storage actual a los contratos del plugin.
- El plugin no accede al storage del core directamente; solo usa los contratos para leer habitos y completions.
- El registro de la pestaña se hace por medio del protocolo `TabPlugin`, y el core solo obtiene `PluginTabItem` desde `PluginRegistry` sin conocer detalles internos.

## Flujo de datos y calculos
- Se registra la completacion del habito en `HabitStatisticsPlugin` (implementa `HabitEventPlugin`) y se persiste en `HabitCompletionRecord`.
- `StatsCalculator` calcula expected/completed por periodo, rachas, mejores dias, comparativas y highlights deterministas.
- Expected se calcula a partir de la frecuencia y el dia de creacion del habito como ancla (diario, semanal por weekday, mensual por dia del mes).

## UI/UX implementada
- `StatsOverviewScreen` con selector de fecha, resumen (periodo seleccionable), grid de 4 recaps y mini visual.
- `RecapDetailScreen` con header KPI, highlights, visual principal por periodo, breakdown por habito y comparativa con periodo anterior.
- Calendario mensual interactivo con detalle del dia (`MonthlyCalendarView` + `DayDetailView`).

## Cambios realizados en el core
- `HabitApp/Infraestructure/Statistics/HabitCompletionRecord.swift`: nuevo modelo SwiftData para historico de completions.
- `HabitApp/Infraestructure/Statistics/StatisticsContracts.swift`: contratos y dependencias para inyeccion.
- `HabitApp/Infraestructure/Statistics/CoreHabitStatsAdapter.swift` y `CoreCompletionStatsAdapter.swift`: adaptadores hacia los contratos.
- `HabitApp/Application/AppConfig.swift`: agrega `HabitCompletionRecord` al schema e inyecta `statisticsDependencies`.
- `HabitApp/Infraestructure/Plugins/TabPlugin.swift` y `PluginRegistry.swift`: soporte de tabs de plugins.
- `HabitApp/Application/HabitApp.swift`: compone tabs a partir del registro del plugin.

## Pregunta clave: ¿Como se inyecta el codigo en la app principal sin aumentar el acoplamiento?
El core registra los plugins en un **punto unico de composicion** (AppConfig + PluginRegistry). El plugin expone su pestaña mediante `TabPlugin` y recibe sus dependencias via `StatisticsDependencies`, que el core construye con adaptadores. Esto mantiene al core independiente de la implementacion interna del plugin: solo conoce contratos, no detalles de UI ni del dominio interno.
