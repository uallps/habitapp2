import SwiftUI

struct HabitStatisticsView: View {
    @ObservedObject var viewModel: HabitStatisticsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            StatLine(title: "Habitos totales", value: "\(viewModel.totalHabits)", systemImage: "checklist", tint: .blue)
            StatLine(title: "Completados hoy", value: "\(viewModel.completedToday)", systemImage: "checkmark.circle.fill", tint: .green)
            ProgressView(value: viewModel.completionRate) {
                Text("Progreso diario")
            }
            .tint(.orange)
            StatLine(title: "Habitos semanales", value: "\(viewModel.weeklyHabits)", systemImage: "calendar", tint: .purple)
        }
        .padding(12)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(12)
    }
}

private struct StatLine: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
                .foregroundColor(tint)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}
