import SwiftUI

struct HabitListView: View {
    @StateObject private var viewModel: HabitListViewModel
    @State private var navigationPath: [UUID] = []
    @State private var newHabitId: UUID?
    @State private var showArchived: Bool = false

#if PREMIUM || PLUGIN_CATEGORIES
    @State private var selectedCategoryFilter: HabitCategory?
    @State private var filteredHabitIds: Set<UUID>?
#endif

    init(storageProvider: StorageProvider) {
        _viewModel = StateObject(wrappedValue: HabitListViewModel(storageProvider: storageProvider))
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
#if PREMIUM || PLUGIN_CATEGORIES
                    if BuildFeatures.supportsCategories {
                        CategoryFilterBar(selectedCategory: $selectedCategoryFilter)
                            .onChange(of: selectedCategoryFilter) { _, newValue in
                                Task { await updateCategoryFilter(newValue) }
                            }
                    }
#endif
                List {
                    if activeIndices.isEmpty {
#if PREMIUM || PLUGIN_CATEGORIES
                        if selectedCategoryFilter != nil {
                            ContentUnavailableView(
                                "Sin hábitos",
                                systemImage: "tray",
                                description: Text("No hay hábitos en esta categoría")
                            )
                        } else {
                            ContentUnavailableView(
                                "Sin hábitos",
                                systemImage: "checklist",
                                description: Text("Añade tu primer hábito")
                            )
                        }
#else
                        ContentUnavailableView(
                            "Sin hábitos",
                            systemImage: "checklist",
                            description: Text("Añade tu primer hábito")
                        )
#endif
                    } else {
                        ForEach(activeIndices, id: \.self) { index in
                            habitRow(habit: $viewModel.habits[index])
                        }
                        .onDelete { indexSet in
                            Task {
                                let indices = indexSet.map { activeIndices[$0] }
                                await viewModel.removeHabits(atOffsets: IndexSet(indices))
                            }
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
                } // End VStack

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
        viewModel.habits.indices.filter { index in
            let habit = viewModel.habits[index]
            guard !habit.isArchived else { return false }
#if PREMIUM || PLUGIN_CATEGORIES
            if let filterIds = filteredHabitIds {
                return filterIds.contains(habit.id)
            }
#endif
            return true
        }
    }

    private var archivedIndices: [Int] {
        viewModel.habits.indices.filter { viewModel.habits[$0].isArchived }
    }

#if PREMIUM || PLUGIN_CATEGORIES
    private func updateCategoryFilter(_ category: HabitCategory?) async {
        guard let category else {
            filteredHabitIds = nil
            return
        }
        let storage = HabitCategorySwiftDataStorage()
        do {
            filteredHabitIds = try await storage.habitIds(for: category)
        } catch {
            print("Error loading category filter: \(error)")
            filteredHabitIds = nil
        }
    }
#endif
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
