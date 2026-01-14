import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appConfig: AppConfig

    var body: some View {
        Form {
#if PREMIUM
            Section(header: Text("Suscripcion")) {
                Toggle("Premium", isOn: $appConfig.isPremium)
            }

            Section(header: Text("Caracteristicas")) {
                ForEach(Array(PluginRegistry.shared.getPluginSettingsViews().enumerated()), id: \.offset) { _, view in
                    view
                }
            }
#else
            Section(header: Text("Version")) {
                Text("Basica")
            }
#endif
        }
        .navigationTitle("Ajustes")
    }
}

#Preview {
    SettingsView().environmentObject(AppConfig())
}
