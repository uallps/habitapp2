import SwiftUI

struct HabitListView: View {
    @StateObject private var viewModel: HabitListViewModel
    @State private var navigationPath: [UUID] = []
    @State private var newHabitId: UUID?
    @State private var showArchived: Bool = false

    init(storageProvider: StorageProvider) {
        _viewModel = StateObject(wrappedValue: HabitListViewModel(storageProvider: storageProvider))
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottomTrailing) {
                List {
                    ForEach(activeIndices, id: \.self) { index in
                        habitRow(habit: $viewModel.habits[index])
                    }
                    .onDelete { indexSet in
                        Task {
                            let indices = indexSet.map { activeIndices[$0] }
                            await viewModel.removeHabits(atOffsets: IndexSet(indices))
                        }
                    }

                    if showArchived, !archivedIndices.isEmpty {
                        Section(header: Text("Archivados")) {
                            ForEach(archivedIndices, id: \.self) { index in
                                ArchivedHabitRowView(habit: viewModel.habits[index])
                                    .listRowBackground(Color.secondary.opacity(0.1))
                            }
                            .onDelete { indexSet in
                                Task {
                                    let indices = indexSet.map { archivedIndices[$0] }
                                    await viewModel.removeHabits(atOffsets: IndexSet(indices))
                                }
                            }
                        }
                    }
                }

                Button {
                    showArchived.toggle()
                } label: {
                    Image(systemName: showArchived ? "archivebox.fill" : "archivebox")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .padding()
            }
            .navigationTitle("Habitos")
            .navigationDestination(for: UUID.self) { habitId in
                if let habitBinding = binding(forID: habitId) {
                    HabitDetailView(
                        habit: habitBinding,
                        isNew: newHabitId == habitId,
                        onSave: {
                            Task { await viewModel.saveChanges() }
                            newHabitId = nil
                        }
                    )
                } else {
                    Text("Habito no encontrado")
                }
            }
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
        NavigationLink(value: habit.wrappedValue.id) {
            HabitRowView(
                habit: habit.wrappedValue,
                isToggleEnabled: habit.wrappedValue.isScheduled(on: Date())
            ) {
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
                newHabitId = newHabit.id
                navigationPath.append(newHabit.id)
            }
        }
    }

    private func binding(forID habitID: UUID) -> Binding<Habit>? {
        guard let index = viewModel.habits.firstIndex(where: { $0.id == habitID }) else { return nil }
        return $viewModel.habits[index]
    }

    private func deleteHabit(withId habitID: UUID) {
        guard let index = viewModel.habits.firstIndex(where: { $0.id == habitID }) else { return }
        Task {
            await viewModel.removeHabits(atOffsets: IndexSet(integer: index))
        }
    }

    private var activeIndices: [Int] {
        viewModel.habits.indices.filter { !viewModel.habits[$0].isArchived }
    }

    private var archivedIndices: [Int] {
        viewModel.habits.indices.filter { viewModel.habits[$0].isArchived }
    }
}

#Preview {
    HabitListView(storageProvider: MockStorageProvider())
}

private struct ArchivedHabitRowView: View {
    let habit: Habit

    var body: some View {
        HStack {
            Image(systemName: "archivebox")
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("Frecuencia: \(frequencyText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
