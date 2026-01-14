import SwiftUI
import Combine

struct DayDetailView: View {
    let detail: StatsDayDetail
    let calendar: Calendar

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dayTitle)
                    .font(.headline)
                Spacer()
                Text("\(detail.completed)/\(detail.expected)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if detail.habits.isEmpty {
                Text("Sin habitos esperados")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(detail.habits) { habit in
                    HStack {
                        Text(habit.name)
                        Spacer()
                        Text(habit.completed >= habit.expected ? "Hecho" : "Pendiente")
                            .font(.caption)
                            .foregroundColor(habit.completed >= habit.expected ? .green : .secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(10)
    }

    private var dayTitle: String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale.current
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: detail.date)
    }
}

