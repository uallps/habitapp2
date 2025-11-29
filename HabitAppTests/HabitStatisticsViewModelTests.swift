import XCTest
@testable import HabitApp

@MainActor
final class HabitStatisticsViewModelTests: XCTestCase {
    func testRefreshCalculatesMetrics() async throws {
        let habits = [
            Habit(name: "Meditar", isCompletedToday: true),
            Habit(name: "Correr", frequency: .weekly),
            Habit(name: "Leer", frequency: .weekly, isCompletedToday: true)
        ]
        let storage = SpyStorageProvider(initialHabits: habits)
        let sut = HabitStatisticsViewModel(storageProvider: storage)

        await sut.refresh()

        XCTAssertEqual(sut.totalHabits, 3)
        XCTAssertEqual(sut.completedToday, 2)
        XCTAssertEqual(sut.weeklyHabits, 2)
        XCTAssertEqual(sut.completionRate, 2.0 / 3.0, accuracy: 0.001)
    }
}
