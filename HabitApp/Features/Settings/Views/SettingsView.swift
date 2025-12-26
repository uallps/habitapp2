import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appConfig: AppConfig

    var body: some View {
        Form {
            Section(header: Text("Suscripcion")) {
                Toggle("Premium", isOn: $appConfig.isPremium)
            }

            Section(header: Text("Características")) {
                ForEach(Array(PluginRegistry.shared.getPluginSettingsViews().enumerated()), id: \.offset) { _, view in
                    view
                }
            }
        }
        .navigationTitle("Ajustes")
    }
}

#Preview {
    SettingsView().environmentObject(AppConfig())
}
