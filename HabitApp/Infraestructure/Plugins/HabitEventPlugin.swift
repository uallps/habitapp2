import Foundation

protocol HabitEventPlugin: FeaturePlugin {
    func habitDidUpdate(_ habit: Habit) async
}
