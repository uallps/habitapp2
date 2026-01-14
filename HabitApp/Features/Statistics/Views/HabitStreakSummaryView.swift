import SwiftUI
import Combine

struct HabitStreakRowView: View {
    let habit: Habit
    @StateObject private var viewModel: HabitStreakSummaryViewModel

    init(habit: Habit, dependencies: StatisticsDependencies) {
        self.habit = habit
        _viewModel = StateObject(wrappedValue: HabitStreakSummaryViewModel(habit: habit, dependencies: dependencies))
    }

    var body: some View {
        Text("🔥 Racha: \(viewModel.currentStreak) · Mejor: \(viewModel.bestStreak)")
            .font(.caption2)
            .foregroundColor(.secondary)
            .onChange(of: habit.isCompletedToday) { _, _ in
                viewModel.refresh(from: habit)
            }
            .onChange(of: habit.lastCompletionDate) { _, _ in
                viewModel.refresh(from: habit)
            }
            .onChange(of: habit.weeklyDays) { _, _ in
                viewModel.refresh(from: habit)
            }
            .onChange(of: habit.frequency) { _, _ in
                viewModel.refresh(from: habit)
            }
            .onChange(of: habit.archivedAt) { _, _ in
                viewModel.refresh(from: habit)
            }
    }
}

struct HabitStreakDetailSummaryView: View {
    let habit: Habit
    @StateObject private var viewModel: HabitStreakSummaryViewModel

    init(habit: Habit, dependencies: StatisticsDependencies) {
        self.habit = habit
        _viewModel = StateObject(wrappedValue: HabitStreakSummaryViewModel(habit: habit, dependencies: dependencies))
    }

    var body: some View {
        HStack {
            Text("🔥 Racha del habito")
            Spacer()
            Text("\(viewModel.currentStreak) / \(viewModel.bestStreak)")
                .foregroundColor(.secondary)
        }
        .font(.subheadline)
        .onChange(of: habit.isCompletedToday) { _, _ in
            viewModel.refresh(from: habit)
        }
        .onChange(of: habit.lastCompletionDate) { _, _ in
            viewModel.refresh(from: habit)
        }
        .onChange(of: habit.weeklyDays) { _, _ in
            viewModel.refresh(from: habit)
        }
        .onChange(of: habit.frequency) { _, _ in
            viewModel.refresh(from: habit)
        }
        .onChange(of: habit.archivedAt) { _, _ in
            viewModel.refresh(from: habit)
        }
    }
}

