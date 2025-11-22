import SwiftUI

struct HabitListView: View {
    @StateObject private var viewModel: HabitListViewModel
    @State private var activeHabitID: UUID?

    init(storageProvider: StorageProvider) {
        _viewModel = StateObject(wrappedValue: HabitListViewModel(storageProvider: storageProvider))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach($viewModel.habits) { $habit in
                    habitRow(habit: $habit)
                }
                .onDelete { indexSet in
                    Task {
                        await viewModel.removeHabits(atOffsets: indexSet)
                    }
                }
            }
            .navigationTitle("Habitos")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    addHabitButton()
                }
#else
                ToolbarItem {
                    addHabitButton()
                }
#endif
            }
            .task {
                await viewModel.loadHabits()
            }
        }
    }

    @ViewBuilder
    private func habitRow(habit: Binding<Habit>) -> some View {
        NavigationLink(
            tag: habit.wrappedValue.id,
            selection: $activeHabitID
        ) {
            HabitDetailView(
                habit: binding(forID: habit.wrappedValue.id),
                onSave: { Task { await viewModel.saveChanges() } }
            )
        } label: {
            HabitRowView(habit: habit.wrappedValue) {
                Task { await viewModel.toggleCompletion(for: habit.wrappedValue) }
            }
        }
#if os(iOS)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deleteHabit(withId: habit.wrappedValue.id)
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
#endif
        .contextMenu {
            Button(role: .destructive) {
                deleteHabit(withId: habit.wrappedValue.id)
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }

    private func addHabitButton() -> some View {
        Button("Anadir habito") {
            Task {
                let newHabit = await viewModel.addHabit()
                activeHabitID = newHabit.id
            }
        }
    }

    private func binding(forID habitID: UUID) -> Binding<Habit> {
        guard let index = viewModel.habits.firstIndex(where: { $0.id == habitID }) else {
            fatalError("Habit not found")
        }
        return $viewModel.habits[index]
    }

    private func deleteHabit(withId habitID: UUID) {
        guard let index = viewModel.habits.firstIndex(where: { $0.id == habitID }) else { return }
        Task {
            await viewModel.removeHabits(atOffsets: IndexSet(integer: index))
            if activeHabitID == habitID {
                activeHabitID = nil
            }
        }
    }
}

#Preview {
    HabitListView(storageProvider: MockStorageProvider())
}
