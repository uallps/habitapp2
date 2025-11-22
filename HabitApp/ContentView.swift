import SwiftUI

struct ContentView: View {
    var body: some View {
        HabitListView(storageProvider: MockStorageProvider())
    }
}

#Preview {
    ContentView()
}
