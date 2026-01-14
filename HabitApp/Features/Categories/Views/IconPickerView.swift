#if PREMIUM || PLUGIN_CATEGORIES
import SwiftUI

/// Vista para seleccionar un icono SF Symbol para una categoría.
/// Organiza los iconos por grupos temáticos y es compatible con iOS y macOS.
struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss
    let accentColor: Color

    private let columns = [
        GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 12)
    ]

    private var groupedIcons: [(String, [CategoryEmoji])] {
        Dictionary(grouping: CategoryEmoji.allCases) { $0.category }
            .sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(groupedIcons, id: \.0) { group, icons in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(group)
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(icons) { icon in
                                    IconButton(
                                        icon: icon.rawValue,
                                        isSelected: selectedIcon == icon.rawValue,
                                        accentColor: accentColor
                                    ) {
                                        selectedIcon = icon.rawValue
                                        dismiss()
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color.adaptiveBackground)
            .navigationTitle("Seleccionar Icono")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Botón individual para seleccionar un icono.
private struct IconButton: View {
    let icon: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? accentColor.opacity(0.2) : Color.adaptiveSecondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isSelected ? accentColor : Color.clear, lineWidth: 2)
                    )

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? accentColor : .primary)
            }
            .frame(width: 50, height: 50)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(icon)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Color Extensions

private extension Color {
    static var adaptiveBackground: Color {
        #if os(iOS)
        return Color(uiColor: .systemGroupedBackground)
        #elseif os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return .secondary.opacity(0.1)
        #endif
    }

    static var adaptiveSecondaryBackground: Color {
        #if os(iOS)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #elseif os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return .secondary.opacity(0.15)
        #endif
    }
}

#Preview("Selector de Icono") {
    IconPickerView(
        selectedIcon: .constant("sparkles"),
        accentColor: .purple
    )
}
#endif
