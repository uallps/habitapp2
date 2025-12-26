import Foundation

@MainActor
protocol DataPlugin: FeaturePlugin {
    func willDeleteHabit(_ habit: Habit) async
    func didDeleteHabit(habitId: UUID) async
}
