import Foundation
import SwiftUI
import SwiftData

final class HabitReminderPlugin: DataPlugin, ViewPlugin {
    private let config: AppConfig

    init(config: AppConfig) {
        self.config = config
    }

    var models: [any PersistentModel.Type] { [HabitReminder.self] }
    var isEnabled: Bool { config.enableReminders && config.storageType == .swiftData }

    func willDeleteHabit(_ habit: Habit) async {
        guard isEnabled else { return }
        try? await HabitReminderSwiftDataStorage().delete(for: habit.id)
    }

    func didDeleteHabit(habitId: UUID) async { }

    @MainActor
    @ViewBuilder
    func habitRowView(for habit: Habit) -> some View {
        if isEnabled {
            HabitReminderRowView(viewModel: HabitReminderViewModel(habit: habit))
        }
    }

    @MainActor
    @ViewBuilder
    func habitDetailView(for habit: Binding<Habit>) -> some View {
        if isEnabled {
            HabitReminderDetailView(viewModel: HabitReminderViewModel(habit: habit.wrappedValue))
        }
    }

    @MainActor
    @ViewBuilder
    func settingsView() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("Recordatorios", isOn: Binding(
                get: { self.config.enableReminders },
                set: { self.config.enableReminders = $0 }
            ))
            .disabled(config.storageType == .json)
            if config.storageType == .json {
                Text("Disponible solo con SwiftData")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
