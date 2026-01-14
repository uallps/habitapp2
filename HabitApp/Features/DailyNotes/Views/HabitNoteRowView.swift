import SwiftUI

struct HabitNoteRowView: View {
    @ObservedObject var viewModel: HabitNoteViewModel

    var body: some View {
        if viewModel.hasNote {
            HStack(spacing: 6) {
                Text("Mood \(viewModel.mood) ? \(HabitNote.label(for: viewModel.mood))")
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
