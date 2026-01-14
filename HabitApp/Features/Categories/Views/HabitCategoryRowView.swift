import SwiftUI

struct HabitCategoryRowView: View {
    @ObservedObject var viewModel: HabitCategoryViewModel

    var body: some View {
        if let category = viewModel.currentCategory {
            Label(category.rawValue, systemImage: category.icon)
                .font(.caption)
                .foregroundColor(.teal)
        }
    }
}

