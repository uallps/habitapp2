import SwiftUI

struct HabitStreakRowView: View {
    @ObservedObject var viewModel: HabitStreakViewModel

    var body: some View {
        Text(viewModel.summary)
            .font(.caption)
            .foregroundColor(.orange)
    }
}
