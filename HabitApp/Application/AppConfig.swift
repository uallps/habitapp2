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
    @AppStorage("enableDailyNotes")
    var enableDailyNotes: Bool = false

    @AppStorage("enableCategories")
    var enableCategories: Bool = true

    @AppStorage("enableStatistics")
    var enableStatistics: Bool = true

    @AppStorage("isPremium")
    var isPremium: Bool = false

    private var plugins: [FeaturePlugin] = []

    var isPremiumEnabled: Bool {
        BuildFeatures.isPremiumBuild && isPremium
    }

    var isDailyNotesEnabled: Bool {
        guard BuildFeatures.supportsDailyNotes else { return false }
        return BuildFeatures.isPremiumBuild ? (isPremium && enableDailyNotes) : true
    }

    var isCategoriesEnabled: Bool {
        guard BuildFeatures.supportsCategories else { return false }
        return BuildFeatures.isPremiumBuild ? (isPremium && enableCategories) : true
    }

    var isStatisticsEnabled: Bool {
        guard BuildFeatures.supportsStatistics else { return false }
        return BuildFeatures.isPremiumBuild ? (isPremium && enableStatistics) : true
    }

    init() {
        PluginRegistry.shared.clearAll()
        let discoveredPlugins = PluginDiscovery.discoverPlugins()
        for pluginType in discoveredPlugins {
            PluginRegistry.shared.register(pluginType)
        }
        plugins = PluginRegistry.shared.createPluginInstances(config: self)
    }

    private lazy var swiftDataProvider: HabitSwiftDataStorageProvider = {
        var schemas: [any PersistentModel.Type] = [Habit.self]
        var seen: Set<ObjectIdentifier> = [
            ObjectIdentifier(Habit.self)
        ]
#if PREMIUM || PLUGIN_STATS
        schemas.append(HabitCompletionRecord.self)
        seen.insert(ObjectIdentifier(HabitCompletionRecord.self))
#endif
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

#if PREMIUM || PLUGIN_STATS
    lazy var statisticsDependencies: StatisticsDependencies = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone.current
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return StatisticsDependencies(
            habitDataSource: CoreHabitStatsAdapter(storageProvider: storageProvider),
            completionDataSource: CoreCompletionStatsAdapter(calendar: calendar),
            calendar: calendar
        )
    }()
#endif
}
