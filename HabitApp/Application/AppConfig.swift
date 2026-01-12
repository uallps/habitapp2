//
//  AppConfig.swift
//  HabitApp
//
//  Created by Codex on 03/12/25.
//
import Foundation
import Combine
import SwiftUI
import SwiftData

final class AppConfig: ObservableObject {
    @AppStorage("enableStreaks")
    var enableStreaks: Bool = true

    @AppStorage("enableDailyNotes")
    var enableDailyNotes: Bool = false

    @AppStorage("enableCategories")
    var enableCategories: Bool = true

    @AppStorage("enableStatistics")
    var enableStatistics: Bool = true

    @AppStorage("isPremium")
    var isPremium: Bool = false

    private var plugins: [FeaturePlugin] = []

    init() {
        PluginRegistry.shared.clearAll()
        let discoveredPlugins = PluginDiscovery.discoverPlugins()
        for pluginType in discoveredPlugins {
            PluginRegistry.shared.register(pluginType)
        }
        plugins = PluginRegistry.shared.createPluginInstances(config: self)
    }

    private lazy var swiftDataProvider: HabitSwiftDataStorageProvider = {
        var schemas: [any PersistentModel.Type] = [Habit.self, HabitCompletionRecord.self]
        var seen: Set<ObjectIdentifier> = [
            ObjectIdentifier(Habit.self),
            ObjectIdentifier(HabitCompletionRecord.self)
        ]
        for plugin in plugins {
            for model in plugin.models {
                let identifier = ObjectIdentifier(model)
                if !seen.contains(identifier) {
                    seen.insert(identifier)
                    schemas.append(model)
                }
            }
        }
        let schema = Schema(schemas)
        return HabitSwiftDataStorageProvider(schema: schema)
    }()

    var storageProvider: StorageProvider {
        swiftDataProvider
    }

    lazy var statisticsDependencies: StatisticsDependencies = {
        let calendar = Calendar.current
        return StatisticsDependencies(
            habitDataSource: CoreHabitStatsAdapter(storageProvider: storageProvider),
            completionDataSource: CoreCompletionStatsAdapter(calendar: calendar),
            calendar: calendar
        )
    }()
}
