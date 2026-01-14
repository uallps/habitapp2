import SwiftUI

struct NoteEditorView: View {
    @Binding var draft: NoteDraft
    let habits: [Habit]
    var allowsHabitSelection: Bool = true
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                if habits.isEmpty {
                    Text("Crea un habito antes de registrar notas")
                        .foregroundColor(.secondary)
                } else {
                    Picker("Habito", selection: $draft.habitId) {
                        ForEach(habits) { habit in
                            Text(habit.name).tag(Optional(habit.id))
                        }
                    }
                    .disabled(!allowsHabitSelection)
                }

                DatePicker("Fecha", selection: $draft.date, displayedComponents: .date)

                Section("Estado de animo") {
                    Picker("Mood", selection: $draft.mood) {
                        ForEach(1...5, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("Estado: \(HabitNote.label(for: draft.mood))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Contenido") {
                    TextEditor(text: $draft.text)
                        .frame(minHeight: 160)
                }
            }
            .navigationTitle(draft.id == nil ? "Nueva nota" : "Editar nota")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar", action: onSave)
                        .disabled(draft.habitId == nil || draft.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
