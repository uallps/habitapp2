import SwiftUI

struct HabitBreakdownRowView: View {
    let stat: StatsHabitStat

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(stat.name)
                    .font(.body)
                    .foregroundColor(stat.isArchived ? .secondary : .primary)
                Text("\(stat.completed)/\(stat.expected)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Racha: \(stat.currentStreak) / Mejor: \(stat.bestStreak)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(rateText)
                .font(.subheadline)
                .foregroundColor(.primary)
            if let badge = stat.badge {
                Text(badgeLabel(for: badge))
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(badgeColor(for: badge).opacity(0.2))
                    .foregroundColor(badgeColor(for: badge))
                    .cornerRadius(6)
            }
        }
    }

    private var rateText: String {
        guard let rate = stat.rate else { return "-" }
        return String(format: "%.0f%%", rate * 100)
    }

    private func badgeLabel(for badge: StatsHabitBadge) -> String {
        switch badge {
        case .top: return "Top"
        case .risk: return "Riesgo"
        }
    }

    private func badgeColor(for badge: StatsHabitBadge) -> Color {
        switch badge {
        case .top: return .green
        case .risk: return .red
        }
    }
}
