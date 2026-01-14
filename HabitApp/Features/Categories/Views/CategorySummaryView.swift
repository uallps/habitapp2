#if PREMIUM || PLUGIN_CATEGORIES
import SwiftUI
import SwiftData
import Combine
import UIKit

/// Vista de resumen que muestra todas las categorías con estadísticas.
/// Presenta una visión general del progreso de hábitos organizados por categoría.
/// Incluye animaciones de entrada, estados de carga y accesibilidad completa.
struct CategorySummaryView: View {
    @StateObject private var viewModel = CategorySummaryViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var hasAppeared = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header con estadísticas globales
                    globalStatsHeader
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 20)

                    // Grid de categorías
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(viewModel.categoryStats.enumerated()), id: \.element.id) { index, stat in
                            CategoryStatCard(stat: stat)
                                .opacity(hasAppeared ? 1 : 0)
                                .offset(y: hasAppeared ? 0 : 20)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.05 + 0.1),
                                    value: hasAppeared
                                )
                        }
                    }
                    .padding(.horizontal)

                    // Mensaje motivacional
                    if hasAppeared && viewModel.overallProgress > 0 {
                        motivationalMessage
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.vertical)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Resumen")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await viewModel.load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Actualizar estadísticas")
                }
            }
            .task {
                await viewModel.load()
                withAnimation(.easeOut(duration: 0.4)) {
                    hasAppeared = true
                }
            }
        }
    }

    private var globalStatsHeader: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total de Hábitos")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.totalHabits)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                }
                Spacer()
                CircularProgressView(
                    progress: viewModel.overallProgress,
                    lineWidth: 8,
                    size: 70,
                    showPercentage: true
                )
            }

            // Barra de progreso general
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("Progreso de hoy", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(viewModel.overallProgress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor)
                            .frame(width: geometry.size.width * viewModel.overallProgress, height: 8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.overallProgress)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Resumen general: \(viewModel.totalHabits) hábitos, \(Int(viewModel.overallProgress * 100))% completados hoy")
    }

    @ViewBuilder
    private var motivationalMessage: some View {
        let message = motivationalText
        HStack {
            Image(systemName: message.icon)
                .foregroundColor(message.color)
            Text(message.text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(message.color.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var motivationalText: (text: String, icon: String, color: Color) {
        let progress = viewModel.overallProgress
        if progress >= 1.0 {
            return ("¡Increíble! Has completado todos tus hábitos de hoy", "star.fill", .yellow)
        } else if progress >= 0.75 {
            return ("¡Excelente progreso! Ya casi terminas", "flame.fill", .orange)
        } else if progress >= 0.5 {
            return ("¡Vas por buen camino! Sigue así", "hand.thumbsup.fill", .green)
        } else if progress > 0 {
            return ("¡Buen comienzo! Cada hábito cuenta", "leaf.fill", .mint)
        } else {
            return ("¡Empieza tu día completando un hábito!", "sun.max.fill", .yellow)
        }
    }
}

/// Tarjeta individual que muestra estadísticas de una categoría.
/// Incluye animación al cambiar valores y soporte para accesibilidad.
private struct CategoryStatCard: View {
    let stat: CategoryStat
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header con icono y contador
            HStack {
                // Icono con fondo
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(stat.category.color.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: stat.category.icon)
                        .font(.title3)
                        .foregroundColor(stat.category.color)
                }

                Spacer()

                // Contador de hábitos
                Text("\(stat.habitCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(stat.category.color)
            }

            // Nombre y descripción
            VStack(alignment: .leading, spacing: 2) {
                Text(stat.category.rawValue)
                    .font(.headline)
                    .lineLimit(1)

                Text(stat.category.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            // Progreso del día con barra personalizada
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(stat.todayProgress >= 1 ? .green : .secondary)
                        Text("\(stat.completedToday)/\(stat.scheduledToday)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(Int(stat.todayProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(stat.category.color)
                                        }

                // Barra de progreso personalizada
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(stat.category.color.opacity(0.2))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(stat.category.color)
                            .frame(width: max(0, geometry.size.width * stat.todayProgress), height: 6)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: stat.todayProgress)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.02), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.97 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stat.category.rawValue): \(stat.habitCount) hábitos, \(stat.completedToday) de \(stat.scheduledToday) completados hoy")
    }
}

/// Vista circular de progreso reutilizable.
/// Muestra un anillo de progreso con porcentaje opcional en el centro.
struct CircularProgressView: View {
    let progress: Double
    var lineWidth: CGFloat = 6
    var size: CGFloat = 50
    var showPercentage: Bool = true
    var color: Color = .accentColor

    var body: some View {
        ZStack {
            // Fondo del círculo
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            // Arco de progreso
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

            // Porcentaje en el centro
            if showPercentage {
                Text("\(Int(min(progress, 1.0) * 100))%")
                    .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                                }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("\(Int(progress * 100)) por ciento completado")
    }
}

/// Modelo de estadísticas por categoría
struct CategoryStat: Identifiable {
    let id = UUID()
    let category: HabitCategory
    var habitCount: Int
    var completedToday: Int
    var scheduledToday: Int

    var todayProgress: Double {
        guard scheduledToday > 0 else { return 0 }
        return Double(completedToday) / Double(scheduledToday)
    }
}

/// ViewModel para la vista de resumen de categorías
@MainActor
final class CategorySummaryViewModel: ObservableObject {
    @Published var categoryStats: [CategoryStat] = []
    @Published var totalHabits: Int = 0
    @Published var overallProgress: Double = 0

    private let storage = HabitCategorySwiftDataStorage()

    func load() async {
        do {
            let assignments = try await storage.allAssignments()

            // Acceder al contexto compartido para obtener hábitos
            guard let context = SwiftDataContext.shared else { return }
            let habitDescriptor = FetchDescriptor<Habit>()
            let habits = try context.fetch(habitDescriptor).filter { !$0.isArchived }
            let habitMap = Dictionary(uniqueKeysWithValues: habits.map { ($0.id, $0) })

            totalHabits = habits.count

            var stats: [HabitCategory: CategoryStat] = [:]
            for category in HabitCategory.allCases {
                stats[category] = CategoryStat(
                    category: category,
                    habitCount: 0,
                    completedToday: 0,
                    scheduledToday: 0
                )
            }

            let today = Date()
            var totalScheduled = 0
            var totalCompleted = 0

            for assignment in assignments {
                guard let habit = habitMap[assignment.habitId] else { continue }

                let category = assignment.categoryValue
                stats[category]?.habitCount += 1

                // Verificar si está programado para hoy
                if habit.isScheduled(on: today) {
                    stats[category]?.scheduledToday += 1
                    totalScheduled += 1

                    // Verificar si está completado hoy usando lastCompletionDate
                    if isCompletedToday(habit: habit, today: today) {
                        stats[category]?.completedToday += 1
                        totalCompleted += 1
                    }
                }
            }

            categoryStats = HabitCategory.allCases.compactMap { stats[$0] }
            overallProgress = totalScheduled > 0 ? Double(totalCompleted) / Double(totalScheduled) : 0
        } catch {
            print("Error loading category summary: \(error)")
        }
    }

    /// Verifica si un hábito fue completado hoy comparando lastCompletionDate
    private func isCompletedToday(habit: Habit, today: Date) -> Bool {
        guard habit.isCompletedToday, let lastCompletion = habit.lastCompletionDate else {
            return false
        }
        return Calendar.current.isDate(lastCompletion, inSameDayAs: today)
    }
}

#Preview {
    CategorySummaryView()
}
#endif
