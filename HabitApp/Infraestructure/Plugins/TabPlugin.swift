import SwiftUI

struct PluginTabItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let view: AnyView
    let order: Int
}

@MainActor
protocol TabPlugin: FeaturePlugin {
    func tabItem() -> PluginTabItem?
}
