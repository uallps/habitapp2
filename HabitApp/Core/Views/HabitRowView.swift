import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let isToggleEnabled: Bool
    let toggleCompletion: () -> Void

    init(habit: Habit, isToggleEnabled: Bool = true, toggleCompletion: @escaping () -> Void) {
        self.habit = habit
        self.isToggleEnabled = isToggleEnabled
        self.toggleCompletion = toggleCompletion
    }

    var body: some View {
        HStack {
            Button(action: toggleCompletion) {
                Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(.plain)
            .disabled(!isToggleEnabled)
            .opacity(isToggleEnabled ? 1 : 0.4)
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                Text("Frecuencia: \(frequencyText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ForEach(Array(PluginRegistry.shared.getHabitRowViews(for: habit).enumerated()), id: \.offset) { _, view in
                    view
                }
            }
        }
    }

    private var frequencyText: String {
        switch habit.frequency {
        case .daily:
            return habit.frequency.description
        case .weekly:
            let labels = weekdayLabels(from: habit.weeklyDays)
            if labels.isEmpty {
                return habit.frequency.description
            }
            return "\(habit.frequency.description) (\(labels.joined(separator: " ")))"
        }
    }

    private func weekdayLabels(from days: [Int]) -> [String] {
        let ordered = [2, 3, 4, 5, 6, 7, 1]
        let labels: [Int: String] = [
            2: "L",
            3: "M",
            4: "X",
            5: "J",
            6: "V",
            7: "S",
            1: "D"
        ]
        return ordered.filter { days.contains($0) }.compactMap { labels[$0] }
    }
}

#Preview {
    HabitRowView(habit: HabitSamples.defaults.first!, toggleCompletion: {})
}
