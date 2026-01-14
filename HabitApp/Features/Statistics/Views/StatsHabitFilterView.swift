import SwiftUI

struct StatsHabitOption: Identifiable, Hashable {
    let id: UUID
    let name: String
    let isArchived: Bool
}

struct StatsHabitFilterView: View {
    let habits: [StatsHabitOption]
    @Binding var selectedHabitId: UUID?

    var body: some View {
        let activeHabits = habits.filter { !$0.isArchived }
        let archivedHabits = habits.filter { $0.isArchived }
        let visibleHabits = activeHabits + archivedHabits

        Picker("Habito", selection: $selectedHabitId) {
            Text("Todos").tag(UUID?.none)
            ForEach(visibleHabits) { habit in
                Text(habitLabel(for: habit))
                    .tag(Optional(habit.id))
            }
        }
        .pickerStyle(.menu)
    }

    private func habitLabel(for habit: StatsHabitOption) -> String {
        habit.isArchived ? "\(habit.name) (Archivado)" : habit.name
    }
}

