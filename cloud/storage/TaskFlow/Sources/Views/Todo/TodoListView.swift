import SwiftUI

struct TodoListView: View {
    @StateObject private var viewModel = TodoListViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.filteredItems.isEmpty {
                    TodoEmptyStateView(onAddTapped: { viewModel.showingAddSheet = true })
                } else {
                    listContent
                }
            }
            .navigationTitle("My Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Segment", selection: $viewModel.filter.segment) {
                            ForEach(TodoFilter.Segment.allCases) { segment in
                                Label(segment.rawValue, systemImage: icon(for: segment))
                                    .tag(segment)
                            }
                        }

                        Divider()

                        Toggle(isOn: $viewModel.filter.showCompleted) {
                            Label("Show Completed", systemImage: "checkmark.circle")
                        }

                        Menu {
                            Button("All Categories") {
                                viewModel.filter.selectedCategory = nil
                            }
                            ForEach(TodoItem.Category.allCases) { category in
                                Button(category.displayName) {
                                    viewModel.filter.selectedCategory = category
                                }
                            }
                        } label: {
                            Label("Category", systemImage: "folder")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.editingItem = nil
                        viewModel.showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Add Task")
                }
            }
            .searchable(text: $viewModel.filter.searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        }
        .sheet(isPresented: $viewModel.showingAddSheet) {
            NavigationView {
                TodoEditView(
                    draft: viewModel.editingItem.map(viewModel.draft(for:)) ?? viewModel.draftForNewItem(),
                    onCancel: { viewModel.showingAddSheet = false },
                    onSave: { draft in
                        if draft.id == nil {
                            viewModel.add(draft)
                        } else {
                            viewModel.update(draft)
                        }
                        viewModel.showingAddSheet = false
                    }
                )
            }
        }
    }

    private var listContent: some View {
        List {
            ForEach(viewModel.filteredItems) { item in
                NavigationLink(destination: TodoDetailView(item: item, onUpdate: { updatedItem in
                    viewModel.update(TodoDraft(item: updatedItem))
                }, onDelete: { itemToDelete in
                    viewModel.delete(itemToDelete)
                })) {
                    TodoRowView(item: item, onToggle: {
                        viewModel.toggleCompletion(for: item)
                    })
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button(action: {
                            viewModel.toggleCompletion(for: item)
                        }) {
                            Label(item.isCompleted ? "Mark as Incomplete" : "Mark as Complete",
                                  systemImage: item.isCompleted ? "circle" : "checkmark.circle.fill")
                        }

                        Button(role: .destructive, action: {
                            viewModel.delete(item)
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .onDelete(perform: viewModel.delete)
        }
        .listStyle(.insetGrouped)
    }

    private func icon(for segment: TodoFilter.Segment) -> String {
        switch segment {
        case .all: return "tray"
        case .today: return "sun.max"
        case .upcoming: return "calendar"
        case .completed: return "checkmark.circle"
        }
    }
}

struct TodoListView_Previews: PreviewProvider {
    static var previews: some View {
        TodoListView()
    }
}
