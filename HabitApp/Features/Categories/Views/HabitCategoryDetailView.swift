#if PREMIUM || PLUGIN_CATEGORIES
import SwiftUI

/// Vista de detalle para seleccionar la categoría de un hábito.
/// Muestra un picker con todas las categorías disponibles,
/// incluyendo icono, color y descripción de cada una.
struct HabitCategoryDetailView: View {
    @ObservedObject var viewModel: HabitCategoryViewModel

    private var selectedCategory: Binding<HabitCategory> {
        Binding(
            get: { viewModel.currentCategory ?? .wellness },
            set: { viewModel.select($0) }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker(selection: selectedCategory) {
                ForEach(HabitCategory.allCases) { category in
                    CategoryPickerRow(category: category)
                        .tag(category)
                }
            } label: {
                HStack {
                    Image(systemName: selectedCategory.wrappedValue.icon)
                        .foregroundColor(selectedCategory.wrappedValue.color)
                        .frame(width: 24)
                    Text("Categoría")
                }
            }
            .accessibilityHint("Selecciona una categoría para organizar este hábito")

            // Mostrar descripción de la categoría seleccionada
            if viewModel.loadingState == .loaded {
                HStack {
                    Text(selectedCategory.wrappedValue.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if viewModel.isSaving {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
                .padding(.top, 4)
                .animation(.easeInOut(duration: 0.2), value: selectedCategory.wrappedValue)
            }
        }
    }
}

/// Fila del picker con icono, nombre y descripción de la categoría
private struct CategoryPickerRow: View {
    let category: HabitCategory

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: category.icon)
                .foregroundColor(category.color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                Text(category.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
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

#Preview("Todas las categorías") {
    NavigationStack {
        List {
            ForEach(HabitCategory.allCases) { category in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(category.color)
                            .font(.title2)
                        Text(category.rawValue)
                            .font(.headline)
                    }
                    Text(category.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack {
                        ForEach(category.examples, id: \.self) { example in
                            Text(example)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(category.color.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Categorías")
    }
}
#endif

