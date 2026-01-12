import Foundation
import SwiftUI
import SwiftData

@MainActor
final class PluginRegistry {
    static let shared = PluginRegistry()

    private(set) var registeredPlugins: [FeaturePlugin.Type] = []
    private var pluginInstances: [FeaturePlugin] = []

    private init() {}

    func register(_ pluginType: FeaturePlugin.Type) {
        guard !registeredPlugins.contains(where: { $0 == pluginType }) else { return }
        registeredPlugins.append(pluginType)
    }

    func createPluginInstances(config: AppConfig) -> [FeaturePlugin] {
        pluginInstances = registeredPlugins.map { $0.init(config: config) }
        return pluginInstances
    }

    func getEnabledModels(from plugins: [FeaturePlugin]) -> [any PersistentModel.Type] {
        plugins.flatMap { $0.isEnabled ? $0.models : [] }
    }

    func notifyHabitWillBeDeleted(_ habit: Habit) async {
        let dataPlugins = pluginInstances.compactMap { $0 as? DataPlugin }
        await withTaskGroup(of: Void.self) { group in
            for plugin in dataPlugins where plugin.isEnabled {
                group.addTask { await plugin.willDeleteHabit(habit) }
            }
        }
    }

    func notifyHabitDidDelete(habitId: UUID) async {
        let dataPlugins = pluginInstances.compactMap { $0 as? DataPlugin }
        await withTaskGroup(of: Void.self) { group in
            for plugin in dataPlugins where plugin.isEnabled {
                group.addTask { await plugin.didDeleteHabit(habitId: habitId) }
            }
        }
    }

    func notifyHabitCompletion(_ habit: Habit) async {
        let eventPlugins = pluginInstances.compactMap { $0 as? HabitEventPlugin }
        await withTaskGroup(of: Void.self) { group in
            for plugin in eventPlugins where plugin.isEnabled {
                group.addTask { await plugin.habitDidUpdate(habit) }
            }
        }
    }

    func getHabitRowViews(for habit: Habit) -> [AnyView] {
        pluginInstances
            .compactMap { $0 as? any ViewPlugin }
            .filter { $0.isEnabled }
            .map { AnyView($0.habitRowView(for: habit)) }
    }

    func getHabitDetailViews(for habit: Binding<Habit>) -> [AnyView] {
        pluginInstances
            .compactMap { $0 as? any ViewPlugin }
            .filter { $0.isEnabled }
            .map { AnyView($0.habitDetailView(for: habit)) }
    }

    func getPluginSettingsViews() -> [AnyView] {
        pluginInstances
            .compactMap { $0 as? any ViewPlugin }
            .map { AnyView($0.settingsView()) }
    }

    func getTabItems() -> [PluginTabItem] {
        pluginInstances
            .compactMap { $0 as? any TabPlugin }
            .filter { $0.isEnabled }
            .compactMap { $0.tabItem() }
            .sorted { $0.order < $1.order }
    }

    func clearAll() {
        registeredPlugins.removeAll()
        pluginInstances.removeAll()
    }
}
