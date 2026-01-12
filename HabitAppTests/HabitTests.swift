import XCTest
@testable import HabitApp

final class HabitTests: XCTestCase {
    func testHabitCodableRoundTrip() throws {
        let habit = Habit(name: "Leer", frequency: .weekly, isCompletedToday: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode([habit])
        let decoded = try decoder.decode([Habit].self, from: data)

        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded.first?.name, habit.name)
        XCTAssertEqual(decoded.first?.frequency, .weekly)
        XCTAssertTrue(decoded.first?.isCompletedToday ?? false)
    }

    func testFrequencyDescriptionMatchesRawValue() {
        for frequency in HabitFrequency.allCases {
            XCTAssertEqual(frequency.description, frequency.rawValue)
        }
    }
}
