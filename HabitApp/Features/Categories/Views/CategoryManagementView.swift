#if PREMIUM || PLUGIN_CATEGORIES
import SwiftUI
import SwiftData
import Combine

/// Vista principal para gestionar categorías.
/// Permite ver, crear, editar y eliminar categorías personalizadas.
struct CategoryManagementView: View {
    @StateObject private var viewModel = CategoryManagementViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showAddCategory = false
    @State private var categoryToEdit: Category?
    @State private var categoryToDelete: Category?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.categories.isEmpty {
                    emptyStateView
                } else {
                    categoryList
                }
            }
            .navigationTitle("Categorías")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddCategory = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Añadir categoría")
                }
            }
            .sheet(isPresented: $showAddCategory) {
                CategoryFormView { category in
                    Task {
                        await viewModel.saveCategory(category)
                    }
                }
            }
            .sheet(item: $categoryToEdit) { category in
                CategoryFormView(category: category) { updatedCategory in
                    Task {
                        await viewModel.saveCategory(updatedCategory)
                    }
                }
            }
            .alert("Eliminar Categoría", isPresented: $showDeleteConfirmation) {
                Button("Cancelar", role: .cancel) {
                    categoryToDelete = nil
                }
                Button("Eliminar", role: .destructive) {
                    if let category = categoryToDelete {
                        Task {
                            await viewModel.deleteCategory(category)
                        }
                    }
                    categoryToDelete = nil
                }
            } message: {
                if let category = categoryToDelete {
                    if category.isDefault {
                        Text("Esta es una categoría por defecto. Los hábitos asignados se moverán a 'Otro'.")
                    } else {
                        let count = viewModel.habitCounts[category.id] ?? 0
                        if count > 0 {
                            Text("\(count) hábito(s) usan esta categoría y serán movidos a 'Otro'.")
                        } else {
                            Text("¿Estás seguro de que quieres eliminar '\(category.name)'?")
                        }
                    }
                }
            }
            .task {
                await viewModel.load()
            }
        }
    }

    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.2)
            Text("Cargando categorías...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No hay categorías")
                .font(.headline)

            Text("Crea tu primera categoría para organizar tus hábitos")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showAddCategory = true
            } label: {
                Label("Crear Categoría", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
    }

    private var categoryList: some View {
        List {
            Section {
                ForEach(viewModel.categories) { category in
                    CategoryRow(
                        category: category,
                        habitCount: viewModel.habitCounts[category.id] ?? 0,
                        onEdit: {
                            categoryToEdit = category
                        },
                        onDelete: {
                            categoryToDelete = category
                            showDeleteConfirmation = true
                        }
                    )
                }
                .onMove { from, to in
                    Task {
                        await viewModel.moveCategories(from: from, to: to)
                    }
                }
            } header: {
                Text("\(viewModel.categories.count) categoría(s)")
            } footer: {
                Text("Mantén pulsado para reordenar. Las categorías por defecto se pueden editar pero no eliminar permanentemente.")
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
    }
}

/// Fila individual de categoría en la lista.
private struct CategoryRow: View {
    let category: Category
    let habitCount: Int
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Icono con fondo de color
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: category.emoji)
                    .font(.title3)
                    .foregroundColor(category.color)
            }

            // Información de la categoría
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(category.name)
                        .font(.headline)

                    if category.isDefault {
                        Text("Por defecto")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    }
                }

                if !category.categoryDescription.isEmpty {
                    Text(category.categoryDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Contador de hábitos
            if habitCount > 0 {
                Text("\(habitCount)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Editar", systemImage: "pencil")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Eliminar", systemImage: "trash")
            }

            Button {
                onEdit()
            } label: {
                Label("Editar", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.name), \(habitCount) hábitos")
        .accessibilityHint("Desliza para editar o eliminar")
    }
}

/// ViewModel para la vista de gestión de categorías.
@MainActor
final class CategoryManagementViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var habitCounts: [UUID: Int] = [:]
    @Published var isLoading = true
    @Published var error: String?

    private let storage = CategorySwiftDataStorage()
    private let assignmentStorage = HabitCategorySwiftDataStorage()

    func load() async {
        isLoading = true
        do {
            // Inicializar categorías por defecto si es necesario
            try await storage.initializeDefaultCategoriesIfNeeded()

            // Cargar categorías
            categories = try await storage.allCategories()

            // Cargar contadores de hábitos por categoría
            var counts: [UUID: Int] = [:]
            for category in categories {
                counts[category.id] = try await storage.habitCount(for: category.id)
            }
            habitCounts = counts
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func saveCategory(_ category: Category) async {
        do {
            try await storage.save(category)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteCategory(_ category: Category) async {
        do {
            // Buscar la categoría "Otro" para reasignar hábitos
            if let otherCategory = try await storage.category(byName: "Otro") {
                try await assignmentStorage.reassignHabits(
                    from: category.id,
                    to: otherCategory.id
                )
            }

            try await storage.delete(categoryId: category.id)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func moveCategories(from source: IndexSet, to destination: Int) async {
        var updatedCategories = categories
        updatedCategories.move(fromOffsets: source, toOffset: destination)

        // Actualizar sortOrder
        for (index, category) in updatedCategories.enumerated() {
            category.sortOrder = index
        }

        // Guardar cambios
        do {
            for category in updatedCategories {
                try await storage.save(category)
            }
            categories = updatedCategories
        } catch {
            self.error = error.localizedDescription
        }
    }
}

#Preview {
    CategoryManagementView()
}
#endif
