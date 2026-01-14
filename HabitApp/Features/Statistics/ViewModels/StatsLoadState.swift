#if PREMIUM || PLUGIN_STATS
import Foundation
import Combine
enum StatsLoadState<T> {
    case loading
    case empty(String)
    case loaded(T)
    case error(String)
}

#endif
