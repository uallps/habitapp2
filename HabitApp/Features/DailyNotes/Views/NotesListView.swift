import SwiftUI

struct NotesListView: View {
    @StateObject private var viewModel: NotesListViewModel

    init(storageProvider: StorageProvider, noteStorage: HabitNoteStorage? = nil) {
        _viewModel = StateObject(wrappedValue: NotesListViewModel(storageProvider: storageProvider, noteStorage: noteStorage))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.notes) { note in
                    Button {
                        viewModel.edit(note: note)
                    } label: {
                        noteRow(note)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            delete(note: note)
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            delete(note: note)
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                }
                .onDelete { indexSet in
                    Task { await viewModel.deleteNotes(at: indexSet) }
                }
            }
#if os(iOS)
            .listStyle(.insetGrouped)
#else
            .listStyle(.inset)
#endif
            .navigationTitle("Notas")
            .toolbar {
                Button(action: viewModel.presentNewNote) {
                    Label("Nueva nota", systemImage: "plus")
                }
                .disabled(viewModel.habits.isEmpty)
            }
            .task { await viewModel.load() }
            .sheet(isPresented: $viewModel.isPresentingEditor) {
                NoteEditorView(
                    draft: $viewModel.draft,
                    habits: viewModel.habits,
                    allowsHabitSelection: true,
                    onCancel: { viewModel.isPresentingEditor = false },
                    onSave: { Task { await viewModel.saveDraft() } }
                )
            }
        }
    }

    private func noteRow(_ note: HabitNote) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.title(for: note.habitId))
                .font(.headline)
            Text(note.date, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(note.text.isEmpty ? "(Sin contenido)" : note.text)
                .font(.body)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func delete(note: HabitNote) {
        Task { await viewModel.delete(note: note) }
    }
}

#Preview {
    NotesListView(storageProvider: MockStorageProvider())
}
