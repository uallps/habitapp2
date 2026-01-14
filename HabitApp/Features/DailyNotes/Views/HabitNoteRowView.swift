#if PREMIUM || PLUGIN_NOTES
﻿import SwiftUI

struct HabitNoteRowView: View {
    @ObservedObject var viewModel: HabitNoteViewModel

    var body: some View {
        if !viewModel.text.isEmpty {
            Text("Nota: \(viewModel.text)")
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(.purple)
        }
    }
}

#endif
