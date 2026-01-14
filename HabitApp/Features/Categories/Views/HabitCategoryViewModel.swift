#if PREMIUM || PLUGIN_CATEGORIES
import Foundation
import Combine

/// Estado de carga del ViewModel
enum CategoryLoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}

/// ViewModel que gestiona la categoría asignada a un hábito.
/// Maneja la carga, selección y persistencia de categorías.
/// Ahora soporta tanto categorías personalizadas (Category) como legacy (HabitCategory).
@MainActor
final class HabitCategoryViewModel: ObservableObject {
    /// Asignación de categoría actual
    @Published private(set) var assignment: HabitCategoryAssignment?

    /// Categoría actual (nuevo modelo)
    @Published private(set) var currentCategory: Category?

    /// Lista de todas las categorías disponibles
    @Published private(set) var availableCategories: [Category] = []

    /// Estado de carga actual
    @Published private(set) var loadingState: CategoryLoadingState = .idle

    /// Indica si hay una operación de guardado en progreso
    @Published private(set) var isSaving: Bool = false

    private let habit: Habit
    private let assignmentStorage: HabitCategoryStorage
    private let categoryStorage: CategoryStorage

    /// Inicializa el ViewModel con un hábito y opcionalmente storages personalizados (útil para testing)
    init(
        habit: Habit,
        assignmentStorage: HabitCategoryStorage? = nil,
        categoryStorage: CategoryStorage? = nil
    ) {
        self.habit = habit
        self.assignmentStorage = assignmentStorage ?? HabitCategorySwiftDataStorage()
        self.categoryStorage = categoryStorage ?? CategorySwiftDataStorage()
        Task { await load() }
    }

    /// Carga la categoría asignada al hábito desde el storage
    func load() async {
        loadingState = .loading
        do {
            // Inicializar categorías por defecto si es necesario
            try await categoryStorage.initializeDefaultCategoriesIfNeeded()

            // Cargar todas las categorías disponibles
            availableCategories = try await categoryStorage.allCategories()

            // Cargar la asignación actual
            assignment = try await assignmentStorage.category(for: habit.id)

            // Si no existe asignación, crear una por defecto
            if assignment == nil {
                if let defaultCategory = try await categoryStorage.defaultCategory() {
                    let newAssignment = HabitCategoryAssignment(habitId: habit.id, categoryId: defaultCategory.id)
                    try await assignmentStorage.save(newAssignment)
                    assignment = newAssignment
                    currentCategory = defaultCategory
                }
            } else if let categoryId = assignment?.categoryId {
                // Cargar la categoría actual
                currentCategory = try await categoryStorage.category(for: categoryId)
            } else if assignment?.isLegacy == true {
                // Migrar asignación legacy
                await migrateLegacyAssignment()
            }

            loadingState = .loaded
        } catch {
            loadingState = .error("Error al cargar categoría")
            print("Category load error: \(error)")
        }
    }

    /// Migra una asignación legacy al nuevo formato
    private func migrateLegacyAssignment() async {
        guard let legacy = assignment?.legacyCategoryValue else { return }

        // Buscar la categoría correspondiente por nombre
        if let category = try? await categoryStorage.category(byName: legacy.rawValue) {
            assignment?.categoryId = category.id
            assignment?.legacyCategory = nil
            currentCategory = category

            if let assignment = assignment {
                try? await assignmentStorage.save(assignment)
            }
        }
    }

    /// Selecciona una nueva categoría para el hábito
    /// - Parameter category: La categoría a asignar
    func select(_ category: Category) {
        let previousCategory = currentCategory

        currentCategory = category

        if assignment == nil {
            assignment = HabitCategoryAssignment(habitId: habit.id, categoryId: category.id)
        } else {
            assignment?.categoryId = category.id
            assignment?.legacyCategory = nil
        }

        Task {
            let success = await persist()
            if !success {
                // Revertir en caso de error
                currentCategory = previousCategory
            }
        }
    }

    /// Persiste la asignación actual en el storage
    /// - Returns: true si se guardó correctamente, false en caso de error
    private func persist() async -> Bool {
        guard let assignment else { return false }
        isSaving = true
        defer { isSaving = false }

        do {
            try await assignmentStorage.save(assignment)
            return true
        } catch {
            print("Category save error: \(error)")
            return false
        }
    }

    /// Recarga las categorías disponibles (útil después de crear/editar/eliminar)
    func refreshCategories() async {
        do {
            availableCategories = try await categoryStorage.allCategories()
        } catch {
            print("Error refreshing categories: \(error)")
        }
    }

    /// ID del hábito asociado
    var habitId: UUID {
        habit.id
    }
}
#endif

