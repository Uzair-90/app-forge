import SwiftUI

struct TodoDetailView: View {
    let item: TodoItem
    let onUpdate: (TodoItem) -> Void
    let onDelete: (TodoItem) -> Void

    @State private var showingEdit = false
    @State private var showingDeleteAlert = false

    private var dueDateText: String? {
        guard let due = item.dueDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = item.hasTime ? .short : .none
        return formatter.string(from: due)
    }

    var body: some View {
        Form {
            Section(header: Text("Task")) {
                HStack {
                    Text("Title")
                    Spacer()
                    Text(item.title)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                }

                Toggle(isOn: .constant(item.isCompleted)) {
                    Text("Completed")
                }
                .disabled(true)

                HStack {
                    Text("Priority")
                    Spacer()
                    Text(item.priority.displayName)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(priorityColor.opacity(0.12))
                        .foregroundColor(priorityColor)
                        .clipShape(Capsule())
                }

                HStack {
                    Text("Category")
                    Spacer()
                    Text(item.category.displayName)
                        .foregroundColor(.secondary)
                }
            }

            if !item.notes.isEmpty {
                Section(header: Text("Notes")) {
                    Text(item.notes)
                        .foregroundColor(.primary)
                }
            }

            Section(header: Text("Schedule")) {
                if let dueText = dueDateText {
                    HStack {
                        Text("Due")
                        Spacer()
                        Text(dueText)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                } else {
                    Text("No due date")
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Task", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEdit = true
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationView {
                TodoEditView(
                    draft: TodoDraft(item: item),
                    onCancel: { showingEdit = false },
                    onSave: { draft in
                        let updated = draft.toTodoItem()
                        onUpdate(updated)
                        showingEdit = false
                    }
                )
            }
        }
        .alert("Delete Task", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete(item)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
    }

    private var priorityColor: Color {
        switch item.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

struct TodoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TodoDetailView(
                item: TodoItem(
                    title: "Prepare presentation",
                    notes: "Update slides and rehearse.",
                    isCompleted: false,
                    dueDate: Date().addingTimeInterval(3600 * 24),
                    hasTime: true,
                    priority: .high,
                    category: .work
                ),
                onUpdate: { _ in },
                onDelete: { _ in }
            )
        }
    }
}
