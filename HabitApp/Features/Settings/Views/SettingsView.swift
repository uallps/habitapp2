import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
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
