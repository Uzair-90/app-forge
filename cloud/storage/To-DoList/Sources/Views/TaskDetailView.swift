import SwiftUI

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: TodoListViewModel
    let item: TodoItem

    @State private var showingEdit: Bool = false

    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(item.isCompleted ? .green : .secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title)
                            .font(.title3.weight(.semibold))
                            .strikethrough(item.isCompleted)

                        if !item.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(item.details)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }

                        if let due = item.dueDate {
                            Label(due, systemImage: "calendar")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 6)
            }

            Section {
                Button {
                    viewModel.toggleCompleted(item)
                } label: {
                    Label(item.isCompleted ? "Mark as Not Completed" : "Mark as Completed", systemImage: item.isCompleted ? "arrow.uturn.left" : "checkmark")
                }

                Button(role: .destructive) {
                    viewModel.delete(item: item)
                    dismiss()
                } label: {
                    Label("Delete Task", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            TodoEditorView(mode: .edit(item)) { title, details, dueDate in
                viewModel.update(item, title: title, details: details, dueDate: dueDate)
            }
        }
    }
}

#Preview {
    NavigationStack {
        let vm = TodoListViewModel()
        let item = TodoItem(title: "Plan trip", details: "Book hotel and flights", isCompleted: false, dueDate: .now)
        TaskDetailView(viewModel: vm, item: item)
    }
}
