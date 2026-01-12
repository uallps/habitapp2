import SwiftUI

struct HabitNoteDetailView: View {
    @ObservedObject var viewModel: HabitNoteViewModel

    var body: some View {
        DatePicker(
            "Fecha",
            selection: Binding(
                get: { viewModel.selectedDate },
                set: { viewModel.updateDate($0) }
            ),
            displayedComponents: [.date]
        )
        TextEditor(text: Binding(
            get: { viewModel.text },
            set: { viewModel.update(text: $0) }
        ))
        .frame(minHeight: 100)
    }
}
