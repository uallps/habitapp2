import SwiftUI

struct StatisticsDashboardView: View {
    @StateObject private var viewModel: HabitStatisticsViewModel

    init(storageProvider: StorageProvider) {
        _viewModel = StateObject(wrappedValue: HabitStatisticsViewModel(storageProvider: storageProvider))
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Resumen") {
                    HabitStatisticsView(viewModel: viewModel)
                }
            }
            .navigationTitle("Estadisticas")
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
}

#Preview {
    StatisticsDashboardView(storageProvider: MockStorageProvider())
}

