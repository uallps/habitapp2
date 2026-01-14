import Foundation
import Combine

@MainActor
final class NotesListViewModel: ObservableObject {
    @Published var notes: [HabitNote] = []
    @Published var habits: [Habit] = []
    @Published var draft = NoteDraft()
    @Published var isPresentingEditor = false

    private let noteStorage: HabitNoteStorage
    private let storageProvider: StorageProvider
    private var editingNote: HabitNote?

    init(storageProvider: StorageProvider, noteStorage: HabitNoteStorage? = nil) {
        self.storageProvider = storageProvider
        self.noteStorage = noteStorage ?? HabitNoteSwiftDataStorage()
    }

    func load() async {
        do {
            notes = try await noteStorage.allNotes()
            notes.sort { $0.date > $1.date }
            habits = try await storageProvider.loadHabits()
            habits.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            print("Notes list load error: \(error)")
        }
    }

    func presentNewNote() {
        draft = NoteDraft(habitId: habits.first?.id)
        editingNote = nil
        isPresentingEditor = true
    }

    func edit(note: HabitNote) {
        draft = NoteDraft(id: note.id, habitId: note.habitId, date: note.date, text: note.text)
        editingNote = note
        isPresentingEditor = true
    }

    func saveDraft() async {
        guard let habitId = draft.habitId else { return }
        do {
            if let existing = editingNote {
                existing.habitId = habitId
                existing.text = draft.text
                existing.update(date: draft.date)
                try await noteStorage.save(existing)
            } else {
                let note = HabitNote(habitId: habitId, date: draft.date, text: draft.text)
                try await noteStorage.save(note)
            }
            editingNote = nil
            draft = NoteDraft(habitId: habits.first?.id)
            isPresentingEditor = false
            await load()
        } catch {
            print("Notes save error: \(error)")
        }
    }

    func delete(note: HabitNote) async {
        do {
            try await noteStorage.delete(note)
            await load()
        } catch {
            print("Notes delete error: \(error)")
        }
    }

    func deleteNotes(at offsets: IndexSet) async {
        do {
            for index in offsets {
                let note = notes[index]
                try await noteStorage.delete(note)
            }
            await load()
        } catch {
            print("Notes delete error: \(error)")
        }
    }

    func title(for habitId: UUID?) -> String {
        guard let habitId else { return "Sin habito" }
        return habits.first(where: { $0.id == habitId })?.name ?? "Habito desconocido"
    }
}

