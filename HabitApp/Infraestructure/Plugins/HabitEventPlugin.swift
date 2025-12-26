import Foundation

@MainActor
protocol HabitEventPlugin: FeaturePlugin {
    func habitDidUpdate(_ habit: Habit) async
}
