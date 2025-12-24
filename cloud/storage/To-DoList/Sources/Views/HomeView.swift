import SwiftUI

/// Legacy entry view retained for compatibility.
/// The app now uses `TodoListView` as the primary home.
struct HomeView: View {
    var body: some View {
        TodoListView()
    }
}

#Preview {
    HomeView()
}