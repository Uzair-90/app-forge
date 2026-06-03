import SwiftUI

@main
struct AppMain: App {
    
    private let container = AppContainer()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(
                    TodoListViewModel(
                        service: container.todoService,
                        reminderManager: container.reminderManager
                    )
                )
        }
    }
}