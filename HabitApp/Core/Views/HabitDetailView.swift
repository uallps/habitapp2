import SwiftUI

struct HabitDetailView: View {
    @Binding var habit: Habit
    var onSave: (() -> Void)?
    var isNew: Bool

    @Environment(\.dismiss) private var dismiss

    init(habit: Binding<Habit>, isNew: Bool = false, onSave: (() -> Void)? = nil) {
        self._habit = habit
        self.isNew = isNew
        self.onSave = onSave
    }

    var body: some View {
        Form {
            Section(header: Text("Informacion")) {
                if isNew {
                    TextField("Nombre del habito", text: $habit.name)
                } else {
                    Text(habit.name)
                }
                Picker("Frecuencia", selection: $habit.frequency) {
                    ForEach(HabitFrequency.allCases) { freq in
                        Text(freq.description).tag(freq)
                    }
                }
                if habit.frequency == .weekly {
                    WeekdayPicker(selectedDays: $habit.weeklyDays)
                }
                Toggle("Completado hoy", isOn: $habit.isCompletedToday)
                    .disabled(!habit.isScheduled(on: Date()))
            }

            Section(header: Text("Complementos")) {
                ForEach(Array(PluginRegistry.shared.getHabitDetailViews(for: $habit).enumerated()), id: \.offset) { _, view in
                    view
                }
            }

            if !habit.isArchived {
                Section(header: Text("Estado")) {
                    Button(role: .destructive) {
                        habit.archivedAt = Date()
                        onSave?()
                        dismiss()
                    } label: {
                        Text("Finalizar habito")
                    }
                }
            }
        }
        .navigationTitle($habit.name)
        .onDisappear {
            onSave?()
        }
        .onChange(of: habit.isCompletedToday) { _, _ in
            if habit.isCompletedToday {
                habit.lastCompletionDate = Date()
            } else {
                habit.lastCompletionDate = nil
            }
            Task { await PluginRegistry.shared.notifyHabitCompletion(habit) }
        }
        .onChange(of: habit.frequency) { _, newValue in
            if newValue == .weekly, habit.weeklyDays.isEmpty {
                habit.weeklyDays = [Calendar.current.component(.weekday, from: Date())]
            }
        }
    }
}

#Preview {
    HabitDetailView(habit: .constant(HabitSamples.defaults.first!))
}

private struct WeekdayPicker: View {
    @Binding var selectedDays: [Int]

    private let options: [(Int, String)] = [
        (2, "L"),
        (3, "M"),
        (4, "X"),
        (5, "J"),
        (6, "V"),
        (7, "S"),
        (1, "D")
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.0) { weekday, label in
                Button {
                    toggleDay(weekday)
                } label: {
                    Text(label)
                        .frame(width: 28, height: 28)
                        .foregroundColor(isSelected(weekday) ? .white : .primary)
                        .background(isSelected(weekday) ? Color.accentColor : Color.secondary.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private func isSelected(_ day: Int) -> Bool {
        selectedDays.contains(day)
    }

    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            if selectedDays.count > 1 {
                selectedDays.removeAll { $0 == day }
            }
        } else {
            selectedDays.append(day)
        }
    }
}
