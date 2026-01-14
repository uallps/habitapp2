#if PREMIUM || PLUGIN_CATEGORIES
import Foundation
import SwiftUI
import SwiftData

@MainActor
final class HabitCategoryPlugin: DataPlugin, ViewPlugin {
    private let config: AppConfig

    init(config: AppConfig) {
        self.config = config
    }

    var models: [any PersistentModel.Type] { [HabitCategoryAssignment.self] }
    var isEnabled: Bool { config.isCategoriesEnabled }

    func willDeleteHabit(_ habit: Habit) async {
        guard isEnabled else { return }
        try? await HabitCategorySwiftDataStorage().delete(for: habit.id)
    }

    func didDeleteHabit(habitId: UUID) async { }

    @MainActor
    @ViewBuilder
    func habitRowView(for habit: Habit) -> some View {
        if isEnabled {
            HabitCategoryRowView(viewModel: HabitCategoryViewModel(habit: habit))
        }
    }

    @MainActor
    @ViewBuilder
    func habitDetailView(for habit: Binding<Habit>) -> some View {
        if isEnabled {
            HabitCategoryDetailView(viewModel: HabitCategoryViewModel(habit: habit.wrappedValue))
        }
    }

    @MainActor
    @ViewBuilder
    func settingsView() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("Categorías", isOn: Binding(
                get: { self.config.enableCategories },
                set: { self.config.enableCategories = $0 }
            ))
            .disabled(!config.isPremium)
            if !config.isPremium {
                Text("Disponible solo en Premium")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#endif
