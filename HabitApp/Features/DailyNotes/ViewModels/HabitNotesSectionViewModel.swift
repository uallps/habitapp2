import Foundation
import Combine

@MainActor
final class HabitNotesSectionViewModel: ObservableObject {
    @Published private(set) var notes: [HabitNote] = []

    private let habit: Habit
    private let noteStorage: HabitNoteStorage
    private var editingNote: HabitNote?

    init(habit: Habit, noteStorage: HabitNoteStorage? = nil) {
        self.habit = habit
        self.noteStorage = noteStorage ?? HabitNoteSwiftDataStorage()
    }

    func load() async {
        do {
            notes = try await noteStorage.notes(for: habit.id)
            notes.sort { $0.date > $1.date }
        } catch {
            print("Habit note list load error: \(error)")
        }
    }

    func draftForNewNote() -> NoteDraft {
        editingNote = nil
        return NoteDraft(habitId: habit.id, date: Date(), text: "")
    }

    func draft(for note: HabitNote) -> NoteDraft {
        editingNote = note
        return NoteDraft(id: note.id, habitId: note.habitId, date: note.date, text: note.text)
    }

    func save(draft: NoteDraft) async {
        do {
            if let existing = editingNote {
                existing.text = draft.text
                existing.update(date: draft.date)
                try await noteStorage.save(existing)
            } else {
                let note = HabitNote(habitId: habit.id, date: draft.date, text: draft.text)
                try await noteStorage.save(note)
            }
            editingNote = nil
            await load()
        } catch {
            print("Habit note save error: \(error)")
        }
    }

    func cancelEditing() {
        editingNote = nil
    }

    func delete(note: HabitNote) async {
        do {
            try await noteStorage.delete(note)
            await load()
        } catch {
            print("Habit note delete error: \(error)")
        }
    }
}

