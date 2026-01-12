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
            GroupBox("Fecha de referencia") {
                DatePicker("Fecha", selection: $viewModel.referenceDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.compact)
            }

            if let summaryRecap = payload.recaps[viewModel.summaryPeriod] {
                GroupBox("Resumen") {
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
                Text("Recaps")
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

            GroupBox("Vista rapida") {
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
            HStack {
                Text("Completados")
                Spacer()
                Text("\(recap.completedTotal)/\(recap.expectedTotal)")
            }
            HStack {
                Text("Cumplimiento")
                Spacer()
                Text(rateText)
            }
            HStack {
                Text("Racha perfecta (global)")
                Spacer()
                Text("\(recap.currentStreak) dias")
            }
        }
        .font(.subheadline)
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
            Text(recap.period.title)
                .font(.headline)
            Text(statusLabel)
                .font(.caption2)
                .foregroundColor(statusColor)
            Text(StatsDateFormatter.rangeText(for: recap.period, interval: recap.interval, calendar: calendar))
                .font(.caption)
                .foregroundColor(.secondary)
            Text(rateText)
                .font(.title3)
                .bold()
            Text("\(recap.completedTotal)/\(recap.expectedTotal)")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(recap.primaryHighlight)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(12)
    }

    private var rateText: String {
        guard let rate = recap.completionRate else { return "-" }
        return String(format: "%.0f%%", rate * 100)
    }

    private var statusLabel: String {
        recap.period.isCurrent(interval: recap.interval, calendar: calendar, relativeTo: Date()) ? "En curso" : "Finalizado"
    }

    private var statusColor: Color {
        recap.period.isCurrent(interval: recap.interval, calendar: calendar, relativeTo: Date()) ? .green : .secondary
    }
}

private struct EmptyStatsView: View {
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Text(message)
                .font(.headline)
            Text("Crear habito")
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
