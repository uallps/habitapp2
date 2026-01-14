import Foundation

enum BuildFeatures {
#if PREMIUM
    static let isPremiumBuild = true
#else
    static let isPremiumBuild = false
#endif

#if PREMIUM || PLUGIN_NOTES
    static let supportsDailyNotes = true
#else
    static let supportsDailyNotes = false
#endif

#if PREMIUM || PLUGIN_CATEGORIES
    static let supportsCategories = true
#else
    static let supportsCategories = false
#endif

#if PREMIUM || PLUGIN_STATS
    static let supportsStatistics = true
#else
    static let supportsStatistics = false
#endif
}
