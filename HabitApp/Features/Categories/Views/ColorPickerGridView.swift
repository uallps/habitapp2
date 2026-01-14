#if PREMIUM || PLUGIN_CATEGORIES
import SwiftUI

/// Vista para seleccionar un color para una categoría.
/// Muestra una cuadrícula de colores predefinidos compatible con iOS y macOS.
struct ColorPickerGridView: View {
    @Binding var selectedColorHex: String
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview del color seleccionado
                colorPreview

                // Grid de colores
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(CategoryColor.allCases) { colorOption in
                        ColorButton(
                            color: colorOption.color,
                            colorHex: colorOption.rawValue,
                            isSelected: selectedColorHex == colorOption.rawValue
                        ) {
                            selectedColorHex = colorOption.rawValue
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 24)
            .background(Color.adaptiveBackground)
            .navigationTitle("Seleccionar Color")
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

    private var colorPreview: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color(hex: selectedColorHex) ?? .gray)
                .frame(width: 60, height: 60)
                .shadow(color: (Color(hex: selectedColorHex) ?? .gray).opacity(0.4), radius: 8, x: 0, y: 4)

            Text(colorName(for: selectedColorHex))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Color seleccionado: \(colorName(for: selectedColorHex))")
    }

    private func colorName(for hex: String) -> String {
        CategoryColor.allCases.first { $0.rawValue == hex }?.name ?? "Personalizado"
    }
}

/// Botón individual para seleccionar un color.
private struct ColorButton: View {
    let color: Color
    let colorHex: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 44, height: 44)
                    .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)

                if isSelected {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 3)
                        .frame(width: 44, height: 44)

                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 50, height: 50)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(CategoryColor.allCases.first { $0.rawValue == colorHex }?.name ?? "Color")
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
}

#Preview("Selector de Color") {
    ColorPickerGridView(
        selectedColorHex: .constant("#AF52DE")
    )
}
#endif
