#if PREMIUM || PLUGIN_CATEGORIES
import SwiftUI

struct HabitCategoryDetailView: View {
    @ObservedObject var viewModel: HabitCategoryViewModel

    private var selectedCategory: Binding<HabitCategory> {
        Binding(
            get: { viewModel.currentCategory ?? .wellness },
            set: { viewModel.select($0) }
        )
    }

    var body: some View {
        Picker(selection: selectedCategory) {
            ForEach(HabitCategory.allCases) { category in
                CategoryPickerRow(category: category)
                    .tag(category)
            }
        } label: {
            HStack {
                Image(systemName: selectedCategory.wrappedValue.icon)
                    .foregroundColor(selectedCategory.wrappedValue.color)
                Text("Categoría")
            }
        }
    }
}

/// Fila del picker con icono y color
private struct CategoryPickerRow: View {
    let category: HabitCategory

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: category.icon)
                .foregroundColor(category.color)
                .frame(width: 20)
            Text(category.rawValue)
            Spacer()
        }
    }
}

#Preview {
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

