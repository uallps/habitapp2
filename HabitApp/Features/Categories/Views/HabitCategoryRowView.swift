#if PREMIUM || PLUGIN_CATEGORIES
import SwiftUI

/// Vista compacta que muestra la categoría de un hábito como badge colorido.
/// Se usa en la lista de hábitos junto al nombre del hábito.
struct HabitCategoryRowView: View {
    @ObservedObject var viewModel: HabitCategoryViewModel

    var body: some View {
        if let category = viewModel.currentCategory {
            CategoryBadge(category: category)
        }
    }
}

/// Badge visual con el icono y nombre de la categoría
struct CategoryBadge: View {
    let category: HabitCategory

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
            Text(category.rawValue)
        }
        .font(.caption2)
        .fontWeight(.medium)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(category.color.opacity(0.15))
        .foregroundColor(category.color)
        .clipShape(Capsule())
    }
}

#Preview("Todos los badges") {
    VStack(spacing: 12) {
        ForEach(HabitCategory.allCases) { category in
            HStack {
                CategoryBadge(category: category)
                Spacer()
                Text(category.rawValue)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
    }
    .padding()
}
#endif

