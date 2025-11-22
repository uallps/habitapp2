import XCTest
@testable import HabitApp

@MainActor
final class HabitListViewModelTests: XCTestCase {
    func testLoadHabitsUsesStorage() async throws {
        let customHabits = [Habit(name: "Yoga"), Habit(name: "Agua", frequency: .weekly)]
        let storage = SpyStorageProvider(initialHabits: customHabits)
        let sut = HabitListViewModel(storageProvider: storage)

        await sut.loadHabits()

        XCTAssertEqual(sut.habits.count, customHabits.count)
        XCTAssertEqual(sut.habits.first?.name, "Yoga")
    }

    func testAddHabitPersistsChanges() async throws {
        let storage = SpyStorageProvider(initialHabits: HabitSamples.defaults)
        let sut = HabitListViewModel(storageProvider: storage)

        await sut.loadHabits()
        await sut.addHabit()

        let saved = await storage.savedHabitsSnapshot()
        XCTAssertEqual(saved.count, HabitSamples.defaults.count + 1)
        XCTAssertEqual(await storage.saveCalls(), 1)
    }

    func testToggleCompletionUpdatesHabit() async throws {
        let storage = SpyStorageProvider(initialHabits: HabitSamples.defaults)
        let sut = HabitListViewModel(storageProvider: storage)

        await sut.loadHabits()
        guard let habit = sut.habits.first else {
            XCTFail("Se esperaba al menos un habito")
            return
        }

        await sut.toggleCompletion(for: habit)

        XCTAssertTrue(sut.habits.first?.isCompletedToday ?? false)
    }

    func testRemoveHabitPersistsDeletion() async throws {
        let storage = SpyStorageProvider(initialHabits: HabitSamples.defaults)
        let sut = HabitListViewModel(storageProvider: storage)

        await sut.loadHabits()
        await sut.removeHabits(atOffsets: IndexSet(integer: 0))

        let saved = await storage.savedHabitsSnapshot()
        XCTAssertEqual(saved.count, HabitSamples.defaults.count - 1)
        XCTAssertEqual(await storage.saveCalls(), 1)
    }
}
