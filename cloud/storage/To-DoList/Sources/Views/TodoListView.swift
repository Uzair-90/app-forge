import SwiftUI

struct TodoListView: View {
    @StateObject private var viewModel = TodoListViewModel()

    @State private var showingCreate: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.items.isEmpty {
                    EmptyStateView(
                        title: "No Tasks",
                        message: "Add a task to start organizing your day.",
                        systemImage: "checklist",
                        actionTitle: "Add Task",
                        action: { showingCreate = true }
                    )
                } else if viewModel.filteredItems.isEmpty {
                    EmptyStateView(
                        title: "No Results",
                        message: "Try a different filter or clear your search.",
                        systemImage: "magnifyingglass",
                        actionTitle: "Clear Search",
                        action: { viewModel.searchText = "" }
                    )
                } else {
                    List {
                        ForEach(viewModel.filteredItems) { item in
                            NavigationLink {
                                TaskDetailView(viewModel: viewModel, item: item)
                            } label: {
                                TodoRowView(item: item) {
                                    viewModel.toggleCompleted(item)
                                }
                            }
                        }
                        .onDelete(perform: viewModel.delete)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("To‑Do")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Filter", selection: $viewModel.filter) {
                            ForEach(TodoFilter.allCases) { f in
                                Text(f.rawValue).tag(f)
                            }
                        }
                        Toggle("Completed to Bottom", isOn: $viewModel.sortCompletedToBottom)
                            .onChange(of: viewModel.sortCompletedToBottom) { _, _ in
                                // Trigger a re-sort + persist ordering.
                                // Any write action will persist; we just re-emit by reassigning.
                                viewModel.objectWillChange.send()
                            }
                        if viewModel.items.contains(where: { $0.isCompleted }) {
                            Button(role: .destructive) {
                                viewModel.clearCompleted()
                            } label: {
                                Label("Clear Completed", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filter and sorting")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add task")
                }
            }
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search tasks")
            .sheet(isPresented: $showingCreate) {
                TodoEditorView(mode: .create) { title, details, dueDate in
                    viewModel.add(title: title, details: details, dueDate: dueDate)
                }
            }
        }
    }
}

#Preview {
    TodoListView()
}
