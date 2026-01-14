#if PREMIUM || PLUGIN_CATEGORIES
import SwiftUI

/// Vista compacta que muestra la categoría de un hábito como badge colorido.
/// Se usa en la lista de hábitos junto al nombre del hábito.
/// Incluye animación de aparición y soporte para accesibilidad.
struct HabitCategoryRowView: View {
    @ObservedObject var viewModel: HabitCategoryViewModel

    var body: some View {
        Group {
            switch viewModel.loadingState {
            case .loading:
                // Placeholder mientras carga
                CategoryBadgePlaceholder()
            case .loaded, .idle:
                if let category = viewModel.currentCategory {
                    CategoryBadge(category: category)
                        .transition(.scale.combined(with: .opacity))
                }
            case .error(_):
                // No mostrar nada en caso de error
                EmptyView()
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.currentCategory)
    }
}

/// Placeholder animado mientras se carga la categoría
private struct CategoryBadgePlaceholder: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .frame(width: 10, height: 10)
            RoundedRectangle(cornerRadius: 4)
                .frame(width: 50, height: 10)
        }
        .foregroundColor(.gray.opacity(0.3))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
        .clipShape(Capsule())
        .opacity(isAnimating ? 0.5 : 1)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

/// Badge visual con el icono y nombre de la categoría.
/// Incluye animaciones sutiles y soporte completo para accesibilidad.
struct CategoryBadge: View {
    let category: HabitCategory

    /// Tamaño del badge (compacto o normal)
    var isCompact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .imageScale(isCompact ? .small : .medium)
            Text(category.rawValue)
        }
        .font(isCompact ? .caption2 : .caption)
        .fontWeight(.medium)
        .padding(.horizontal, isCompact ? 6 : 8)
        .padding(.vertical, isCompact ? 3 : 4)
        .background(category.color.opacity(0.15))
        .foregroundColor(category.color)
        .clipShape(Capsule())
        .accessibilityLabel(category.accessibilityLabel)
        .accessibilityAddTraits(.isStaticText)
    }
}

#Preview("Todos los badges") {
    VStack(spacing: 16) {
        Text("Badges normales")
            .font(.headline)

        ForEach(HabitCategory.allCases) { category in
            HStack {
                CategoryBadge(category: category)
                Spacer()
                Text(category.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }

        Divider()

        Text("Badges compactos")
            .font(.headline)

        HStack(spacing: 8) {
            ForEach(HabitCategory.allCases) { category in
                CategoryBadge(category: category, isCompact: true)
            }
        }
    }
    .padding()
}
#endif

