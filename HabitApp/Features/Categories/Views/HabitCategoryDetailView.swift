import SwiftUI

struct HabitCategoryDetailView: View {
    @ObservedObject var viewModel: HabitCategoryViewModel

    var body: some View {
        Picker("Categoría", selection: Binding(
            get: { viewModel.currentCategory ?? .wellness },
            set: { viewModel.select($0) }
        )) {
            ForEach(HabitCategory.allCases) { category in
                Label(category.rawValue, systemImage: category.icon).tag(category)
            }
        }
    }
}
