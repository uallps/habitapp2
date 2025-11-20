import SwiftUI

protocol ViewPlugin: FeaturePlugin {
    associatedtype HabitRowContent: View
    associatedtype HabitDetailContent: View
    associatedtype SettingsContent: View

    @ViewBuilder
    func habitRowView(for habit: Habit) -> HabitRowContent

    @ViewBuilder
    func habitDetailView(for habit: Binding<Habit>) -> HabitDetailContent

    @ViewBuilder
    func settingsView() -> SettingsContent
}
