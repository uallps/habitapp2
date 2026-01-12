import Foundation

enum StatsLoadState<T> {
    case loading
    case empty(String)
    case loaded(T)
    case error(String)
}
