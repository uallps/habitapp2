import SwiftUI

struct StatsOverviewScreen: View {
    @StateObject private var viewModel: StatsOverviewViewModel
    private let dependencies: StatisticsDependencies
    @State private var quickViewSelectedHabitId: UUID? = nil

    init(dependencies: StatisticsDependencies) {
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: StatsOverviewViewModel(dependencies: dependencies))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                content
                    .padding()
            }
            .navigationTitle("Estadisticas")
            .refreshable {
                await viewModel.refresh()
            }
            .onAppear {
                viewModel.setReferenceDateToToday()
            }
            .onChange(of: viewModel.referenceDate) { _, _ in
                Task { await viewModel.refresh() }
                viewModel.resetQuickView()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Cargando estadisticas")
                .frame(maxWidth: .infinity, alignment: .center)
        case .empty(let message):
            EmptyStatsView(message: message)
        case .error(let message):
            Text(message)
                .foregroundColor(.secondary)
        case .loaded(let payload):
            loadedContent(payload)
        }
    }

    @ViewBuilder
    private func loadedContent(_ payload: StatsOverviewContent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("📅 Fecha de referencia") {
                DatePicker("Fecha", selection: $viewModel.referenceDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.compact)
            }

            if let summaryRecap = payload.recaps[viewModel.summaryPeriod] {
                GroupBox("✨ Resumen") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Periodo", selection: $viewModel.summaryPeriod) {
                            ForEach(StatsPeriod.allCases) { period in
                                Text(period.title).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)

                        StatsSummaryCard(recap: summaryRecap)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("📊 Recaps")
                    .font(.headline)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(StatsPeriod.allCases) { period in
                        if let recap = payload.recaps[period] {
                            NavigationLink {
                                RecapDetailScreen(
                                    period: period,
                                    referenceDate: viewModel.referenceDate,
                                    dependencies: dependencies
                                )
                            } label: {
                                RecapCardView(recap: recap, calendar: dependencies.calendar)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            GroupBox("⚡ Vista rapida") {
                VStack(alignment: .leading, spacing: 12) {
                    if !viewModel.habits.isEmpty {
                        StatsHabitFilterView(
                            habits: viewModel.habits.map { habit in
                                StatsHabitOption(
                                    id: habit.id,
                                    name: habit.name,
                                    isArchived: habit.archivedAt != nil
                                )
                            },
                            selectedHabitId: $quickViewSelectedHabitId
                        )
                    }

                    StatsQuickCalendarView(
                        recap: viewModel.quickViewRecap,
                        monthDate: viewModel.quickViewMonth,
                        isLoading: viewModel.isQuickViewLoading,
                        calendar: dependencies.calendar,
                        selectedDate: $viewModel.quickViewSelectedDate,
                        selectedHabitId: $quickViewSelectedHabitId,
                        onMoveMonth: { offset in
                            viewModel.moveQuickViewMonth(by: offset)
                        }
                    )
                }
            }
        }
    }
}

private struct StatsSummaryCard: View {
    let recap: StatsRecap

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            StatMetricRow(
                title: "Completados",
                value: "\(recap.completedTotal)/\(recap.expectedTotal)",
                systemImage: "checkmark.seal.fill",
                tint: .green
            )
            StatMetricRow(
                title: "Cumplimiento",
                value: rateText,
                systemImage: "chart.pie.fill",
                tint: .blue
            )
            StatMetricRow(
                title: "Racha perfecta",
                value: "\(recap.currentStreak) dias",
                systemImage: "flame.fill",
                tint: .orange
            )
        }
        .font(.subheadline)
        .padding(12)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(12)
    }

    private var rateText: String {
        guard let rate = recap.completionRate else { return "-" }
        return String(format: "%.0f%%", rate * 100)
    }
}

private struct RecapCardView: View {
    let recap: StatsRecap
    let calendar: Calendar

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    Text(periodEmoji)
                        .font(.title3)
                        .frame(width: 28, height: 28)
                        .background(periodColor.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
                    Text(recap.period.title)
                        .font(.headline)
                }
                Spacer()
                Text(statusLabel)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15), in: Capsule())
                    .foregroundColor(statusColor)
            }
            Text(StatsDateFormatter.rangeText(for: recap.period, interval: recap.interval, calendar: calendar))
                .font(.caption)
                .foregroundColor(.secondary)
            Text(rateText)
                .font(.title3.weight(.bold))
                .foregroundColor(periodColor)
            Text("\(recap.completedTotal)/\(recap.expectedTotal)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(Color.secondary.opacity(0.08), in: Capsule())
            progressBar
            Text(recap.primaryHighlight)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .frame(minHeight: 32, alignment: .topLeading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundStyle)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(statusColor.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private var rateText: String {
        guard let rate = recap.completionRate else { return "-" }
        return String(format: "%.0f%%", rate * 100)
    }

    private var statusLabel: String {
        recap.period.isCurrent(interval: recap.interval, calendar: calendar, relativeTo: Date()) ? "🔥 En curso" : "✅ Finalizado"
    }

    private var statusColor: Color {
        recap.period.isCurrent(interval: recap.interval, calendar: calendar, relativeTo: Date()) ? .green : .secondary
    }

    private var periodEmoji: String {
        switch recap.period {
        case .daily:
            return "☀️"
        case .weekly:
            return "📆"
        case .monthly:
            return "🗓️"
        case .yearly:
            return "📅"
        }
    }

    private var periodColor: Color {
        switch recap.period {
        case .daily:
            return .orange
        case .weekly:
            return .blue
        case .monthly:
            return .purple
        case .yearly:
            return .teal
        }
    }

    private var progressValue: Double {
        min(max(recap.completionRate ?? 0, 0), 1)
    }

    private var progressColor: Color {
        guard let rate = recap.completionRate else { return .secondary }
        if rate >= 1 {
            return .green
        }
        if rate >= 0.8 {
            return .mint
        }
        if rate >= 0.5 {
            return .orange
        }
        if rate > 0 {
            return .red
        }
        return .secondary
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(progressColor.opacity(0.18))
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: 3)
                    .fill(progressColor)
                    .frame(width: geometry.size.width * progressValue, height: 6)
            }
        }
        .frame(height: 6)
        .accessibilityLabel("Progreso \(Int(progressValue * 100)) por ciento")
    }

    private var backgroundStyle: some View {
        let colors = [
            statusColor.opacity(0.18),
            statusColor.opacity(0.05)
        ]
        return RoundedRectangle(cornerRadius: 12)
            .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}

private struct EmptyStatsView: View {
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Text("📭 \(message)")
                .font(.headline)
            Text("✨ Crear habito")
                .font(.headline)
                .foregroundColor(.accentColor)
            Text("Usa la pestana Habitos para agregar el primero.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
    }
}

private struct StatMetricRow: View {
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
                .foregroundColor(.primary)
        }
    }
}

