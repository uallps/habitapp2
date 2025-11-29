import SwiftUI

struct HabitStatisticsView: View {
    @ObservedObject var viewModel: HabitStatisticsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Hábitos totales")
                Spacer()
                Text("\(viewModel.totalHabits)")
            }
            HStack {
                Text("Completados hoy")
                Spacer()
                Text("\(viewModel.completedToday)")
            }
            ProgressView(value: viewModel.completionRate) {
                Text("Progreso diario")
            }
            HStack {
                Text("Hábitos semanales")
                Spacer()
                Text("\(viewModel.weeklyHabits)")
            }
        }
    }
}
