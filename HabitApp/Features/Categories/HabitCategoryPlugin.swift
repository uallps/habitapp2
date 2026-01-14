#if PREMIUM || PLUGIN_CATEGORIES
import Foundation
import SwiftUI
import SwiftData

@MainActor
final class HabitCategoryPlugin: DataPlugin, ViewPlugin {
    private let config: AppConfig

    init(config: AppConfig) {
        self.config = config
    }

    /// Registra ambos modelos: Category y HabitCategoryAssignment
    var models: [any PersistentModel.Type] { [Category.self, HabitCategoryAssignment.self] }
    var isEnabled: Bool { config.isCategoriesEnabled }

    func willDeleteHabit(_ habit: Habit) async {
        guard isEnabled else { return }
        try? await HabitCategorySwiftDataStorage().delete(for: habit.id)
    }

    func didDeleteHabit(habitId: UUID) async { }

    @MainActor
    @ViewBuilder
    func habitRowView(for habit: Habit) -> some View {
        if isEnabled {
            HabitCategoryRowView(viewModel: HabitCategoryViewModel(habit: habit))
        }
    }

    @MainActor
    @ViewBuilder
    func habitDetailView(for habit: Binding<Habit>) -> some View {
        if isEnabled {
            HabitCategoryDetailView(viewModel: HabitCategoryViewModel(habit: habit.wrappedValue))
        }
    }

    @MainActor
    @ViewBuilder
    func settingsView() -> some View {
        CategorySettingsSection(config: config)
    }
}

/// Sección de configuración de categorías con acceso a gestión
private struct CategorySettingsSection: View {
    @ObservedObject var config: AppConfig
    @State private var showCategoryManagement = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Categorías", isOn: Binding(
                get: { config.enableCategories },
                set: { config.enableCategories = $0 }
            ))
            .disabled(!config.isPremium)

            if !config.isPremium {
                Text("Disponible solo en Premium")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if config.isCategoriesEnabled {
                Button {
                    showCategoryManagement = true
                } label: {
                    HStack {
                        Image(systemName: "folder.badge.gearshape")
                        Text("Gestionar Categorías")
                    }
                    .font(.subheadline)
                }
                .padding(.top, 4)
            }
        }
        .sheet(isPresented: $showCategoryManagement) {
            CategoryManagementView()
        }
    }
}
#endif

