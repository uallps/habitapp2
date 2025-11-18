import Foundation

final class HabitJSONStorageProvider: StorageProvider {
    static let shared = HabitJSONStorageProvider()

    private let fileURL: URL

    init(filename: String = "habits.json") {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documentsDirectory.appendingPathComponent(filename)
    }

    func loadHabits() async throws -> [Habit] {
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let defaults = HabitSamples.defaults
            try await saveHabits(defaults)
            return defaults
        }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Habit].self, from: data)
    }

    func saveHabits(_ habits: [Habit]) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(habits)
        try data.write(to: fileURL, options: .atomic)
    }
}
