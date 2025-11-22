import SwiftUI

struct HabitDetailView: View {
    @Binding var habit: Habit
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    init(habit: Binding<Habit>, onSave: (() -> Void)? = nil) {
        self._habit = habit
        self.onSave = onSave
    }

    var body: some View {
        Form {
            Section(header: Text("Información")) {
                TextField("Nombre del hábito", text: $habit.name)
                Picker("Frecuencia", selection: $habit.frequency) {
                    ForEach(HabitFrequency.allCases) { freq in
                        Text(freq.description).tag(freq)
                    }
                }
                Toggle("Completado hoy", isOn: $habit.isCompletedToday)
            }

            Section(header: Text("Complementos")) {
                ForEach(Array(PluginRegistry.shared.getHabitDetailViews(for: $habit).enumerated()), id: \.offset) { _, view in
                    view
                }
            }
        }
        .navigationTitle($habit.name)
        .onDisappear {
            onSave?()
        }
        .onChange(of: habit.isCompletedToday) { _ in
            Task { await PluginRegistry.shared.notifyHabitCompletion(habit) }
        }
    }
}

#Preview {
    HabitDetailView(habit: .constant(HabitSamples.defaults.first!))
}
