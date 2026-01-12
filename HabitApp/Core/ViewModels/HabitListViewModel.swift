//
//  HabitListViewModel.swift
//  HabitApp
//
//  Created by Codex on 03/12/25.
//
import Foundation
import Combine
import SwiftUI

@MainActor
final class HabitListViewModel: ObservableObject {
    @Published var habits: [Habit] = []

    private let storageProvider: StorageProvider

    init(storageProvider: StorageProvider) {
        self.storageProvider = storageProvider
    }

    func loadHabits() async {
        do {
            habits = try await storageProvider.loadHabits()
        } catch {
            print("Error loading habits: \(error)")
            habits = []
        }
    }

    @discardableResult
    func addHabit() async -> Habit {
        let newHabit = Habit(name: "Nuevo habito", frequency: .daily)
        habits.append(newHabit)
        await persist()
        return newHabit
    }

    func removeHabits(atOffsets offsets: IndexSet) async {
        let habitsToDelete = offsets.map { habits[$0] }
        for habit in habitsToDelete {
            await PluginRegistry.shared.notifyHabitWillBeDeleted(habit)
        }
        habits.remove(atOffsets: offsets)
        await persist()
        for habit in habitsToDelete {
            await PluginRegistry.shared.notifyHabitDidDelete(habitId: habit.id)
        }
    }

    func toggleCompletion(for habit: Habit) async {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        guard !habits[index].isArchived else { return }
        guard habits[index].isScheduled(on: Date()) else { return }
        habits[index].isCompletedToday.toggle()
        if habits[index].isCompletedToday {
            habits[index].lastCompletionDate = Date()
        } else {
            habits[index].lastCompletionDate = nil
        }
        await PluginRegistry.shared.notifyHabitCompletion(habits[index])
        await persist()
    }

    func saveChanges() async {
        await persist()
    }

    private func persist() async {
        do {
            try await storageProvider.saveHabits(habits)
        } catch {
            print("Error saving habits: \(error)")
        }
    }
}
