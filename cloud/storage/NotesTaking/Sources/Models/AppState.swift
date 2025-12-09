import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var user: Bool = false
    @Published var isLoading: Bool = false
}

class ContentViewModel: ObservableObject {
    @Published var items: [String] = []
    @Published var error: Error?
    
    func loadData() async {
        // Async data loading
    }
}