#if PREMIUM || PLUGIN_STATS
import SwiftUI

struct BarEntry: Identifiable {
    let id = UUID()
    let label: String
    let completed: Int
    let expected: Int

    var completionRate: Double {
        guard expected > 0 else { return 0 }
        return Double(completed) / Double(expected)
    }
}

struct BarChartView: View {
    let entries: [BarEntry]
    var maxHeight: CGFloat = 64

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(entries) { entry in
                VStack(spacing: 6) {
                    ZStack(alignment: .bottom) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.15))
                            .frame(width: 10, height: maxHeight)
                        Capsule()
                            .fill(color(for: entry))
                            .frame(width: 10, height: maxHeight * CGFloat(entry.completionRate))
                    }
                    Text(entry.label)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .frame(width: 24)
                }
            }
        }
    }

    private func color(for entry: BarEntry) -> Color {
        if entry.expected == 0 {
            return Color.gray.opacity(0.3)
        }
        if entry.completed == 0 {
            return Color.red.opacity(0.6)
        }
        if entry.completed >= entry.expected {
            return Color.green.opacity(0.7)
        }
        return Color.orange.opacity(0.7)
    }
}

#endif
