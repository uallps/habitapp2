import SwiftUI

struct StatsHabitOption: Identifiable, Hashable {
    let id: UUID
    let name: String
    let isArchived: Bool
}

struct StatsHabitFilterView: View {
    let habits: [StatsHabitOption]
    @Binding var selectedHabitId: UUID?
    @Binding var showArchived: Bool

    var body: some View {
        let activeHabits = habits.filter { !$0.isArchived }
        let archivedHabits = habits.filter { $0.isArchived }
        let visibleHabits = activeHabits + (showArchived ? archivedHabits : [])

        VStack(alignment: .leading, spacing: 6) {
            Picker("Habito", selection: $selectedHabitId) {
                Text("Todos").tag(UUID?.none)
                ForEach(visibleHabits) { habit in
                    Text(habitLabel(for: habit))
                        .tag(Optional(habit.id))
                }
            }
            .pickerStyle(.menu)

            if !archivedHabits.isEmpty {
                Toggle("Mostrar archivados", isOn: $showArchived)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onChange(of: showArchived) { _, newValue in
            guard !newValue, let selected = selectedHabitId else { return }
            if archivedHabits.contains(where: { $0.id == selected }) {
                selectedHabitId = nil
            }
        }
    }

    private func habitLabel(for habit: StatsHabitOption) -> String {
        habit.isArchived ? "\(habit.name) (Archivado)" : habit.name
    }
}
