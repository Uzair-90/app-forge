import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var errorHandler = ErrorHandler()
    @Published var isLoading: Bool = false
    @Published var user: User? = nil
    @Published var isLoggedIn: Bool = false
    @Published var user: Bool = false
    @Published var isLoading: Bool = false
    
    /// Cached list of all projects, primarily for state restoration.
    public var projects: [TodoProject] = []
    
    /// Cached list of all tags, primarily for state restoration.
    public var tags: [TodoTag] = []
}

class ContentViewModel: ObservableObject {
    @Published var items: [String] = []
    @Published var error: Error?
    
    func loadData() async {
        // Async data loading
    }
}