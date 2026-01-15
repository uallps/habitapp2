#if PREMIUM || PLUGIN_CATEGORIES
import SwiftUI
import Combine

/// Vista de formulario para crear o editar una categoría.
/// Permite configurar nombre, icono, color y descripción.
struct CategoryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CategoryFormViewModel

    let isEditing: Bool
    let onSave: (Category) -> Void

    init(category: Category? = nil, onSave: @escaping (Category) -> Void) {
        self.isEditing = category != nil
        self.onSave = onSave
        _viewModel = StateObject(wrappedValue: CategoryFormViewModel(category: category))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Preview de la categoría
                Section {
                    categoryPreview
                }

                // Nombre
                Section {
                    TextField("Nombre de la categoría", text: $viewModel.name)
                        .textContentType(.name)
                        .accessibilityLabel("Nombre de la categoría")
                } header: {
                    Text("Nombre")
                } footer: {
                    if viewModel.nameError != nil {
                        Text(viewModel.nameError!)
                            .foregroundColor(.red)
                    }
                }

                // Icono
                Section {
                    iconPickerButton
                } header: {
                    Text("Icono")
                }

                // Color
                Section {
                    colorPickerButton
                } header: {
                    Text("Color")
                }

                // Descripción
                Section {
                    TextField("Descripción (opcional)", text: $viewModel.categoryDescription, axis: .vertical)
                        .lineLimit(2...4)
                        .accessibilityLabel("Descripción de la categoría")
                } header: {
                    Text("Descripción")
                } footer: {
                    Text("Breve descripción de qué tipo de hábitos incluir")
                }
            }
            .navigationTitle(isEditing ? "Editar Categoría" : "Nueva Categoría")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveCategory()
                    }
                    .disabled(!viewModel.isValid)
                }
            }
            .sheet(isPresented: $viewModel.showIconPicker) {
                IconPickerView(
                    selectedIcon: $viewModel.emoji,
                    accentColor: viewModel.color
                )
            }
            .sheet(isPresented: $viewModel.showColorPicker) {
                ColorPickerGridView(
                    selectedColorHex: $viewModel.colorHex
                )
            }
        }
    }

    private var categoryPreview: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(viewModel.color.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: viewModel.emoji)
                        .font(.system(size: 36))
                        .foregroundColor(viewModel.color)
                }
                .shadow(color: viewModel.color.opacity(0.3), radius: 8, x: 0, y: 4)

                Text(viewModel.name.isEmpty ? "Nueva Categoría" : viewModel.name)
                    .font(.headline)

                if !viewModel.categoryDescription.isEmpty {
                    Text(viewModel.categoryDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Vista previa de la categoría")
    }

    private var iconPickerButton: some View {
        Button {
            viewModel.showIconPicker = true
        } label: {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(viewModel.color.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: viewModel.emoji)
                        .font(.title3)
                        .foregroundColor(viewModel.color)
                }

                Text("Cambiar icono")
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityLabel("Seleccionar icono")
        .accessibilityHint("Abre el selector de iconos")
    }

    private var colorPickerButton: some View {
        Button {
            viewModel.showColorPicker = true
        } label: {
            HStack {
                Circle()
                    .fill(viewModel.color)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                    )

                Text(viewModel.colorName)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityLabel("Seleccionar color")
        .accessibilityHint("Abre el selector de colores")
    }

    private func saveCategory() {
        let category = viewModel.buildCategory()
        onSave(category)
        dismiss()
    }
}

/// ViewModel para el formulario de categoría.
@MainActor
final class CategoryFormViewModel: ObservableObject {
    @Published var name: String
    @Published var emoji: String
    @Published var colorHex: String
    @Published var categoryDescription: String
    @Published var showIconPicker = false
    @Published var showColorPicker = false

    private let existingId: UUID?
    private let isDefault: Bool
    private let sortOrder: Int
    private let createdAt: Date

    init(category: Category? = nil) {
        self.existingId = category?.id
        self.name = category?.name ?? ""
        self.emoji = category?.emoji ?? "sparkles"
        self.colorHex = category?.colorHex ?? CategoryColor.purple.rawValue
        self.categoryDescription = category?.categoryDescription ?? ""
        self.isDefault = category?.isDefault ?? false
        self.sortOrder = category?.sortOrder ?? 0
        self.createdAt = category?.createdAt ?? Date()
    }

    var color: Color {
        Color(hex: colorHex) ?? .gray
    }

    var colorName: String {
        CategoryColor.allCases.first { $0.rawValue == colorHex }?.name ?? "Personalizado"
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var nameError: String? {
        if name.isEmpty { return nil }
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "El nombre no puede estar vacío"
        }
        if name.count > 30 {
            return "El nombre es demasiado largo (máx. 30 caracteres)"
        }
        return nil
    }

    func buildCategory() -> Category {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = categoryDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        return Category(
            id: existingId ?? UUID(),
            name: trimmedName,
            emoji: emoji,
            colorHex: colorHex,
            categoryDescription: trimmedDescription,
            isDefault: isDefault,
            sortOrder: sortOrder,
            createdAt: createdAt
        )
    }
}

#Preview("Nueva Categoría") {
    CategoryFormView { category in
        print("Saved: \(category.name)")
    }
}

#Preview("Editar Categoría") {
    CategoryFormView(
        category: Category(
            name: "Bienestar",
            emoji: "sparkles",
            colorHex: "#AF52DE",
            categoryDescription: "Meditación, mindfulness, autocuidado"
        )
    ) { category in
        print("Saved: \(category.name)")
    }
}
#endif

