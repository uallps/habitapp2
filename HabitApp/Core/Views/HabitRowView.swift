import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let toggleCompletion: () -> Void

    var body: some View {
        HStack {
            Button(action: toggleCompletion) {
                Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                Text("Frecuencia: \(habit.frequency.description)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ForEach(Array(PluginRegistry.shared.getHabitRowViews(for: habit).enumerated()), id: \.offset) { _, view in
                    view
                }
            }
        }
    }
}

#Preview {
    HabitRowView(habit: HabitSamples.defaults.first!, toggleCompletion: {})
}
