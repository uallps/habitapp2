#if PREMIUM || PLUGIN_CATEGORIES
import Foundation
import SwiftData

/// Protocolo que define las operaciones de almacenamiento para categorías personalizadas.
@MainActor
protocol CategoryStorage {
    /// Obtiene todas las categorías ordenadas por sortOrder
    func allCategories() async throws -> [Category]

    /// Obtiene una categoría por su ID
    func category(for id: UUID) async throws -> Category?

    /// Guarda una categoría (crea nueva o actualiza existente)
    func save(_ category: Category) async throws

    /// Elimina una categoría por su ID
    func delete(categoryId: UUID) async throws

    /// Inicializa las categorías por defecto si no existen
    func initializeDefaultCategoriesIfNeeded() async throws

    /// Obtiene la primera categoría por defecto (para asignar a nuevos hábitos)
    func defaultCategory() async throws -> Category?

    /// Busca una categoría por nombre (para migración de datos legacy)
    func category(byName name: String) async throws -> Category?

    /// Cuenta cuántos hábitos usan una categoría específica
    func habitCount(for categoryId: UUID) async throws -> Int
}

/// Implementación de CategoryStorage usando SwiftData.
@MainActor
final class CategorySwiftDataStorage: CategoryStorage {
    private var context: ModelContext? { SwiftDataContext.shared }

    func allCategories() async throws -> [Category] {
        guard let context else { return [] }
        let descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    func category(for id: UUID) async throws -> Category? {
        guard let context else { return nil }
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    func save(_ category: Category) async throws {
        guard let context else { return }
        let categoryId = category.id

        // Buscar si ya existe
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.id == categoryId }
        )
        let existing = try context.fetch(descriptor)

        if let existingCategory = existing.first {
            // Actualizar campos existentes
            existingCategory.name = category.name
            existingCategory.emoji = category.emoji
            existingCategory.colorHex = category.colorHex
            existingCategory.categoryDescription = category.categoryDescription
            existingCategory.sortOrder = category.sortOrder
        } else {
            // Insertar nueva categoría
            context.insert(category)
        }
        try context.save()
    }

    func delete(categoryId: UUID) async throws {
        guard let context else { return }
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.id == categoryId }
        )
        let categories = try context.fetch(descriptor)
        for category in categories {
            context.delete(category)
        }
        if !categories.isEmpty {
            try context.save()
        }
    }

    func initializeDefaultCategoriesIfNeeded() async throws {
        guard let context else { return }

        // Verificar si ya existen categorías
        let descriptor = FetchDescriptor<Category>()
        let existingCategories = try context.fetch(descriptor)

        if existingCategories.isEmpty {
            // Crear categorías por defecto
            let defaults = Category.createDefaultCategories()
            for category in defaults {
                context.insert(category)
            }
            try context.save()
        }
    }

    func defaultCategory() async throws -> Category? {
        guard let context else { return nil }
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.isDefault == true },
            sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
        )
        return try context.fetch(descriptor).first
    }

    func category(byName name: String) async throws -> Category? {
        guard let context else { return nil }
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.name == name }
        )
        return try context.fetch(descriptor).first
    }

    func habitCount(for categoryId: UUID) async throws -> Int {
        guard let context else { return 0 }
        let descriptor = FetchDescriptor<HabitCategoryAssignment>(
            predicate: #Predicate { $0.categoryId == categoryId }
        )
        return try context.fetchCount(descriptor)
    }
}

// MARK: - Actualización de HabitCategoryStorage para soportar nuevo modelo

extension HabitCategorySwiftDataStorage {
    /// Actualiza la asignación de categoría de un hábito con el nuevo modelo
    func updateAssignment(habitId: UUID, categoryId: UUID) async throws {
        guard let context else { return }

        let descriptor = FetchDescriptor<HabitCategoryAssignment>(
            predicate: #Predicate { $0.habitId == habitId }
        )
        let existing = try context.fetch(descriptor)

        if let assignment = existing.first {
            assignment.categoryId = categoryId
            assignment.legacyCategory = nil
        } else {
            let newAssignment = HabitCategoryAssignment(habitId: habitId, categoryId: categoryId)
            context.insert(newAssignment)
        }
        try context.save()
    }

    /// Migra asignaciones legacy al nuevo formato
    func migrateLegacyAssignments() async throws {
        guard let context else { return }

        let categoryStorage = CategorySwiftDataStorage()

        // Obtener todas las asignaciones
        let descriptor = FetchDescriptor<HabitCategoryAssignment>()
        let assignments = try context.fetch(descriptor)

        for assignment in assignments {
            // Solo migrar si es legacy y no tiene categoryId
            if assignment.isLegacy, let legacyCategory = assignment.legacyCategoryValue {
                // Buscar la categoría correspondiente por nombre
                if let category = try await categoryStorage.category(byName: legacyCategory.rawValue) {
                    assignment.categoryId = category.id
                    assignment.legacyCategory = nil
                }
            }
        }

        try context.save()
    }

    /// Obtiene todas las asignaciones para una categoría específica
    func assignments(for categoryId: UUID) async throws -> [HabitCategoryAssignment] {
        guard let context else { return [] }
        let descriptor = FetchDescriptor<HabitCategoryAssignment>(
            predicate: #Predicate { $0.categoryId == categoryId }
        )
        return try context.fetch(descriptor)
    }

    /// Reasigna todos los hábitos de una categoría a otra (útil antes de eliminar)
    func reassignHabits(from sourceCategoryId: UUID, to targetCategoryId: UUID) async throws {
        guard let context else { return }

        let descriptor = FetchDescriptor<HabitCategoryAssignment>(
            predicate: #Predicate { $0.categoryId == sourceCategoryId }
        )
        let assignments = try context.fetch(descriptor)

        for assignment in assignments {
            assignment.categoryId = targetCategoryId
        }

        if !assignments.isEmpty {
            try context.save()
        }
    }
}
#endif
