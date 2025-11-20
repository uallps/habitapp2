import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appConfig: AppConfig

    var body: some View {
        Form {
            Section(header: Text("Características")) {
                ForEach(Array(PluginRegistry.shared.getPluginSettingsViews().enumerated()), id: \.offset) { _, view in
                    view
                }
            }

            Section(header: Text("Datos")) {
                Picker("Almacenamiento", selection: $appConfig.storageType) {
                    ForEach(StorageType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
            }
        }
        .navigationTitle("Ajustes")
    }
}

#Preview {
    SettingsView().environmentObject(AppConfig())
}
