import SwiftUI

struct HabitReminderDetailView: View {
    @ObservedObject var viewModel: HabitReminderViewModel

    var body: some View {
        Toggle(isOn: Binding(
            get: { viewModel.hasReminder },
            set: { viewModel.setEnabled($0) }
        )) {
            Text("Recordatorio diario")
        }
        if viewModel.hasReminder {
            DatePicker(
                "Hora",
                selection: Binding(
                    get: { viewModel.reminderDate },
                    set: { viewModel.update(date: $0) }
                ),
                displayedComponents: [.hourAndMinute]
            )
        }
    }
}
