#if PREMIUM || PLUGIN_CATEGORIES
import SwiftUI

/// Vista de detalle para seleccionar la categoría de un hábito.
/// Muestra un picker con todas las categorías disponibles (personalizadas),
/// incluyendo icono, color y descripción de cada una.
struct HabitCategoryDetailView: View {
    @ObservedObject var viewModel: HabitCategoryViewModel
    @State private var showCategoryManagement = false

    private var selectedCategoryId: Binding<UUID?> {
        Binding(
            get: { viewModel.currentCategory?.id },
            set: { newId in
                if let id = newId,
                   let category = viewModel.availableCategories.first(where: { $0.id == id }) {
                    viewModel.select(category)
                }
            }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.loadingState == .loading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Cargando...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                Picker(selection: selectedCategoryId) {
                    ForEach(viewModel.availableCategories) { category in
                        CategoryPickerRow(category: category)
                            .tag(category.id as UUID?)
                    }
                } label: {
                    HStack {
                        if let current = viewModel.currentCategory {
                            Image(systemName: current.emoji)
                                .foregroundColor(current.color)
                                .frame(width: 24)
                        }
                        Text("Categoría")
                    }
                }
                .accessibilityHint("Selecciona una categoría para organizar este hábito")

                // Mostrar descripción de la categoría seleccionada
                if viewModel.loadingState == .loaded, let current = viewModel.currentCategory {
                    HStack {
                        Text(current.categoryDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        if viewModel.isSaving {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                    .padding(.top, 4)
                    .animation(.easeInOut(duration: 0.2), value: current.id)
                }

                // Botón para gestionar categorías
                Button {
                    showCategoryManagement = true
                } label: {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("Gestionar categorías")
                            .font(.subheadline)
                    }
                    .foregroundColor(.accentColor)
                }
                .padding(.top, 8)
            }
        }
        .sheet(isPresented: $showCategoryManagement) {
            CategoryManagementView()
                .onDisappear {
                    Task {
                        await viewModel.refreshCategories()
                    }
                }
        }
    }
}

/// Fila del picker con icono, nombre y descripción de la categoría
private struct CategoryPickerRow: View {
    let category: Category

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: category.emoji)
                .foregroundColor(category.color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                if !category.categoryDescription.isEmpty {
                    Text(category.categoryDescription)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .accessibilityLabel(category.accessibilityLabel)
    }
}

#Preview("En formulario") {
    NavigationStack {
        Form {
            Section(header: Text("Complementos")) {
                HabitCategoryDetailView(
                    viewModel: HabitCategoryViewModel(
                        habit: Habit(name: "Ejemplo")
                    )
                )
            }
        }
    }
}
#endif

