import SwiftUI

struct HabitNoteRowView: View {
    @StateObject private var viewModel: HabitNoteViewModel

    init(habit: Habit, storage: HabitNoteStorage? = nil) {
        _viewModel = StateObject(wrappedValue: HabitNoteViewModel(habit: habit, storage: storage))
    }

    var body: some View {
        if viewModel.hasNote {
            HStack(spacing: 6) {
                Text("Estado: \(HabitNote.label(for: viewModel.mood))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                if !viewModel.text.isEmpty {
                    Text("Nota: \(viewModel.text)")
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundColor(.purple)
                }
            }
        }
    }
}
