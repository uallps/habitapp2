import SwiftUI

struct HabitReminderRowView: View {
    @ObservedObject var viewModel: HabitReminderViewModel

    var body: some View {
        if viewModel.hasReminder {
            Label(
                "Recordatorio: \(viewModel.reminderDate.formatted(date: .omitted, time: .shortened))",
                systemImage: "bell"
            )
            .font(.caption)
            .foregroundStyle(.blue)
        }
    }
}
