import SwiftUI

struct HabitStreakDetailView: View {
    @ObservedObject var viewModel: HabitStreakViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Racha actual", systemImage: "flame.fill")
                Spacer()
                Text("\(viewModel.streak.current) días")
            }
            HStack {
                Label("Mejor racha", systemImage: "trophy.fill")
                Spacer()
                Text("\(viewModel.streak.best) días")
            }
        }
    }
}
