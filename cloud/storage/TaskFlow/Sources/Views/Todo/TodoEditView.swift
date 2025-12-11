import SwiftUI

struct TodoEditView: View {
    @Environment(\.dismiss) private var dismiss

    @State var draft: TodoDraft
    let onCancel: () -> Void
    let onSave: (TodoDraft) -> Void

    @State private var showValidationAlert = false

    private var isValid: Bool {
        !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section(header: Text("Task")) {
                TextField("Title", text: $draft.title)

                TextEditor(text: $draft.notes)
                    .frame(minHeight: 80)
            }

            Section(header: Text("Details")) {
                Picker("Priority", selection: $draft.priority) {
                    ForEach(TodoItem.Priority.allCases) { priority in
                        Text(priority.displayName).tag(priority)
                    }
                }

                Picker("Category", selection: $draft.category) {
                    ForEach(TodoItem.Category.allCases) { category in
                        Text(category.displayName).tag(category)
                    }
                }

                Toggle("Completed", isOn: $draft.isCompleted)
            }

            Section(header: Text("Due Date")) {
                Toggle("Set Due Date", isOn: Binding(
                    get: { draft.dueDate != nil },
                    set: { newValue in
                        if newValue {
                            if draft.dueDate == nil { draft.dueDate = Date() }
                        } else {
                            draft.dueDate = nil
                            draft.hasTime = false
                        }
                    }
                ))

                if let dueDate = draft.dueDate {
                    DatePicker(
                        "Date",
                        selection: Binding(
                            get: { dueDate },
                            set: { newValue in draft.dueDate = newValue }
                        ),
                        displayedComponents: [.date]
                    )

                    Toggle("Include Time", isOn: $draft.hasTime)

                    if draft.hasTime {
                        DatePicker(
                            "Time",
                            selection: Binding(
                                get: { draft.dueDate ?? Date() },
                                set: { newValue in draft.dueDate = newValue }
                            ),
                            displayedComponents: [.hourAndMinute]
                        )
                    }
                }
            }
        }
        .navigationTitle(draft.id == nil ? "New Task" : "Edit Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    onCancel()
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    guard isValid else {
                        showValidationAlert = true
                        return
                    }
                    onSave(draft)
                    dismiss()
                }
                .bold()
            }
        }
        .alert("Missing Title", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please enter a title for this task before saving.")
        }
    }
}

struct TodoEditView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TodoEditView(
                draft: TodoDraft(),
                onCancel: {},
                onSave: { _ in }
            )
        }

        NavigationView {
            TodoEditView(
                draft: TodoDraft(item: TodoItem(
                    title: "Sample",
                    notes: "Some notes",
                    isCompleted: false,
                    dueDate: Date(),
                    hasTime: true,
                    priority: .high,
                    category: .work
                )),
                onCancel: {},
                onSave: { _ in }
            )
        }
    }
}
