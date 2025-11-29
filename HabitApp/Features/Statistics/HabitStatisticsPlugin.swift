import Foundation
import SwiftData
import SwiftUI
import Combine

final class HabitStatisticsPlugin: ViewPlugin {
    private let config: AppConfig

    init(config: AppConfig) {
        self.config = config
    }

    var models: [any PersistentModel.Type] { [] }
    var isEnabled: Bool { config.enableStatistics }

    @MainActor
    @ViewBuilder
    func habitRowView(for habit: Habit) -> some View {
        EmptyView()
    }

    @MainActor
    @ViewBuilder
    func habitDetailView(for habit: Binding<Habit>) -> some View {
        EmptyView()
    }

    @MainActor
    @ViewBuilder
    func settingsView() -> some View {
        HabitStatisticsSettingsView()
    }
}
