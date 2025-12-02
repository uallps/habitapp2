import Foundation
import SwiftUI
import SwiftData

final class HabitNotePlugin: DataPlugin, ViewPlugin {
    private let config: AppConfig

    init(config: AppConfig) {
        self.config = config
    }

    var models: [any PersistentModel.Type] { [HabitNote.self] }
    var isEnabled: Bool { config.enableDailyNotes && config.storageType == .swiftData }

    func willDeleteHabit(_ habit: Habit) async {
        guard isEnabled else { return }
        try? await HabitNoteSwiftDataStorage().deleteNotes(for: habit.id)
    }

    func didDeleteHabit(habitId: UUID) async { }

    @MainActor
    @ViewBuilder
    func habitRowView(for habit: Habit) -> some View {
        if isEnabled {
            HabitNoteRowView(viewModel: HabitNoteViewModel(habit: habit))
        }
    }

    @MainActor
    @ViewBuilder
    func habitDetailView(for habit: Binding<Habit>) -> some View {
        if isEnabled {
            HabitNotesSectionView(habit: habit.wrappedValue)
        }
    }

    @MainActor
    @ViewBuilder
    func settingsView() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("Notas diarias", isOn: Binding(
                get: { self.config.enableDailyNotes },
                set: { self.config.enableDailyNotes = $0 }
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
