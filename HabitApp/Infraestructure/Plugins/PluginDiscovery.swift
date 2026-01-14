import Foundation
import ObjectiveC.runtime

enum PluginDiscovery {
    static func discoverPlugins() -> [FeaturePlugin.Type] {
        var plugins: [FeaturePlugin.Type] = []
        if let executableName = Bundle.main.executablePath?.components(separatedBy: "/").last {
            let expectedCount = objc_getClassList(nil, 0)
            let classes = UnsafeMutablePointer<AnyClass?>.allocate(capacity: Int(expectedCount))
            let autoreleasing = AutoreleasingUnsafeMutablePointer<AnyClass>(classes)
            let actualCount = objc_getClassList(autoreleasing, expectedCount)

            for index in 0 ..< actualCount {
                guard let candidate = classes[Int(index)] else { continue }
                let className = NSStringFromClass(candidate)
                guard className.hasPrefix(executableName) else { continue }
                if let pluginType = candidate as? FeaturePlugin.Type {
                    plugins.append(pluginType)
                }
            }

            classes.deallocate()
        }

        if plugins.isEmpty {
#if PREMIUM || PLUGIN_CATEGORIES
            plugins.append(HabitCategoryPlugin.self)
#endif
#if PREMIUM || PLUGIN_NOTES
            plugins.append(HabitNotePlugin.self)
#endif
#if PREMIUM || PLUGIN_STATS
            plugins.append(HabitStatisticsPlugin.self)
#endif
        }

        return plugins.sorted { priority(for: $0) < priority(for: $1) }
    }

    private static func priority(for plugin: FeaturePlugin.Type) -> Int {
#if PREMIUM || PLUGIN_CATEGORIES
        if plugin is HabitCategoryPlugin.Type {
            return 20
        }
#endif
#if PREMIUM || PLUGIN_NOTES
        if plugin is HabitNotePlugin.Type {
            return 30
        }
#endif
#if PREMIUM || PLUGIN_STATS
        if plugin is HabitStatisticsPlugin.Type {
            return 40
        }
#endif
        return 100
    }
}
