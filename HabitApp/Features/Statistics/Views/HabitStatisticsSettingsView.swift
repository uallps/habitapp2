import SwiftUI

struct HabitStatisticsSettingsView: View {
    @EnvironmentObject private var appConfig: AppConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("Estadisticas", isOn: Binding(
                get: { appConfig.enableStatistics },
                set: { appConfig.enableStatistics = $0 }
            ))
            .disabled(!appConfig.isPremium)
            if !appConfig.isPremium {
                Text("Disponible solo en Premium")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    HabitStatisticsSettingsView()
        .environmentObject(AppConfig())
}
