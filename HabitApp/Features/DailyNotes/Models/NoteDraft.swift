import Foundation

struct NoteDraft: Identifiable {
    var id: UUID? = nil
    var habitId: UUID? = nil
    var date: Date = Date()
    var text: String = ""
}
