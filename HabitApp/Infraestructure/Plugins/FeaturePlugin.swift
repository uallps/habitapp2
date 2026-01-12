import Foundation
import SwiftData

@MainActor
protocol FeaturePlugin: AnyObject {
    var models: [any PersistentModel.Type] { get }
    var isEnabled: Bool { get }
    init(config: AppConfig)
}
