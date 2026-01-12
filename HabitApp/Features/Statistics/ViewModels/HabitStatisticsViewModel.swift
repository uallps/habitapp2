import Foundation
import Combine

@MainActor
final class HabitStatisticsViewModel: ObservableObject {
    @Published private(set) var totalHabits: Int = 0
    @Published private(set) var completedToday: Int = 0
    @Published private(set) var weeklyHabits: Int = 0

    private let storageProvider: StorageProvider

    init(storageProvider: StorageProvider) {
        self.storageProvider = storageProvider
        Task { await refresh() }
    }

    func refresh() async {
        do {
            let habits = try await storageProvider.loadHabits().filter { !$0.isArchived }
            totalHabits = habits.count
            completedToday = habits.filter { $0.isCompletedToday }.count
            weeklyHabits = habits.filter { $0.frequency == .weekly }.count
        } catch {
            print("Stats load error: \(error)")
        }
    }

    var completionRate: Double {
        guard totalHabits > 0 else { return 0 }
        return Double(completedToday) / Double(totalHabits)
    }
}

