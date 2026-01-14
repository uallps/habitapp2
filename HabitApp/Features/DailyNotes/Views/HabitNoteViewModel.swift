import Foundation
import Combine

@MainActor
final class HabitNoteViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var selectedDate: Date = Date()
    @Published var mood: Int = 3
    @Published var hasNote = false

    private var note: HabitNote?
    private let habit: Habit
    private let storage: HabitNoteStorage

    init(habit: Habit, storage: HabitNoteStorage? = nil) {
        self.habit = habit
        self.storage = storage ?? HabitNoteSwiftDataStorage()
        Task { await loadNote() }
    }

    func loadNote() async {
        do {
            note = try await storage.note(for: habit.id, on: selectedDate)
            text = note?.text ?? ""
            mood = note?.mood ?? 3
            hasNote = note != nil
        } catch {
            print("Notes load error: \(error)")
        }
    }

    func update(text: String) {
        self.text = text
        note?.text = text
        Task { await save() }
    }

    func updateDate(_ date: Date) {
        selectedDate = date
        Task { await loadNote() }
    }

    private func save() async {
        guard let note else { return }
        do {
            try await storage.save(note)
        } catch {
            print("Notes save error: \(error)")
        }
    }
}
