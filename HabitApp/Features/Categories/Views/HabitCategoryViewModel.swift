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
@MainActor
final class HabitCategoryViewModel: ObservableObject {
    /// Asignación de categoría actual
    @Published private(set) var assignment: HabitCategoryAssignment?

    /// Estado de carga actual
    @Published private(set) var loadingState: CategoryLoadingState = .idle

    /// Indica si hay una operación de guardado en progreso
    @Published private(set) var isSaving: Bool = false

    private let habit: Habit
    private let storage: HabitCategoryStorage

    /// Inicializa el ViewModel con un hábito y opcionalmente un storage personalizado (útil para testing)
    init(habit: Habit, storage: HabitCategoryStorage? = nil) {
        self.habit = habit
        self.storage = storage ?? HabitCategorySwiftDataStorage()
        Task { await load() }
    }

    /// Carga la categoría asignada al hábito desde el storage
    func load() async {
        loadingState = .loading
        do {
            assignment = try await storage.category(for: habit.id)

            // Si no existe asignación, crear una por defecto
            if assignment == nil {
                let newAssignment = HabitCategoryAssignment(habitId: habit.id, category: .wellness)
                try await storage.save(newAssignment)
                assignment = newAssignment
            }
            loadingState = .loaded
        } catch {
            loadingState = .error("Error al cargar categoría")
            print("Category load error: \(error)")
        }
    }

    /// Selecciona una nueva categoría para el hábito
    /// - Parameter category: La categoría a asignar
    func select(_ category: HabitCategory) {
        let previousCategory = assignment?.categoryValue

        if assignment == nil {
            assignment = HabitCategoryAssignment(habitId: habit.id, category: category)
        } else {
            assignment?.categoryValue = category
        }

        Task {
            let success = await persist()
            if !success {
                // Revertir en caso de error
                assignment?.categoryValue = previousCategory ?? .wellness
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
            try await storage.save(assignment)
            return true
        } catch {
            print("Category save error: \(error)")
            return false
        }
    }

    /// Categoría actualmente seleccionada
    var currentCategory: HabitCategory? {
        assignment?.categoryValue
    }

    /// ID del hábito asociado
    var habitId: UUID {
        habit.id
    }
}
#endif

