import SwiftUI

struct HabitNotesSectionView: View {
    @StateObject private var viewModel: HabitNotesSectionViewModel
    @State private var editorDraft = NoteDraft()
    @State private var isPresentingEditor = false

    private let habit: Habit

    init(habit: Habit, noteStorage: HabitNoteStorage = HabitNoteSwiftDataStorage()) {
        self.habit = habit
        _viewModel = StateObject(wrappedValue: HabitNotesSectionViewModel(habit: habit, noteStorage: noteStorage))
    }

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        Section("Notas") {
            if viewModel.notes.isEmpty {
                Text("Aun no hay notas para este habito")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.notes) { note in
                        noteCard(note)
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task { await viewModel.delete(note: note) }
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.vertical, 4)
            }

            Button {
                editorDraft = viewModel.draftForNewNote()
                isPresentingEditor = true
            } label: {
                Label("Agregar nota", systemImage: "plus")
            }
        }
        .task { await viewModel.load() }
        .sheet(isPresented: $isPresentingEditor) {
            NoteEditorView(
                draft: $editorDraft,
                habits: [habit],
                allowsHabitSelection: false,
                onCancel: {
                    viewModel.cancelEditing()
                    isPresentingEditor = false
                },
                onSave: {
                    Task {
                        await viewModel.save(draft: editorDraft)
                        isPresentingEditor = false
                    }
                }
            )
        }
    }

    private func noteCard(_ note: HabitNote) -> some View {
        Button {
            editorDraft = viewModel.draft(for: note)
            isPresentingEditor = true
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(note.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(note.text.isEmpty ? "(Sin contenido)" : note.text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.yellow.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
