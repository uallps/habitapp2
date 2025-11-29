import SwiftUI

struct HabitStatisticsSettingsView: View {
    @EnvironmentObject private var appConfig: AppConfig

    var body: some View {
        Toggle("Estadisticas", isOn: Binding(
            get: { appConfig.enableStatistics },
            set: { appConfig.enableStatistics = $0 }
        ))
    }
}

#Preview {
    HabitStatisticsSettingsView()
        .environmentObject(AppConfig())
}
