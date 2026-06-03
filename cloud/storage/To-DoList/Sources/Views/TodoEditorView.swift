import SwiftUI

struct TodoEditorView: View {
    enum Mode {
        case create
        case edit(TodoItem)

        var navigationTitle: String {
            switch self {
            case .create: return "New Task"
            case .edit: return "Edit Task"
            }
        }

        var existingItem: TodoItem? {
            switch self {
            case .create: return nil
            case .edit(let item): return item
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    let mode: Mode
    let onSave: (_ title: String, _ details: String, _ dueDate: Date?) -> Void

    @State private var title: String = ""
    @State private var details: String = ""
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()

    @FocusState private var titleFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .focused($titleFocused)

                    TextField("Notes", text: $details, axis: .vertical)
                        .lineLimit(3...8)
                } header: {
                    Text("Task")
                }

                Section {
                    Toggle("Due Date", isOn: $hasDueDate.animation(.default))
                    if hasDueDate {
                        DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                    }
                } header: {
                    Text("Schedule")
                }
            }
            .navigationTitle(mode.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(title, details, hasDueDate ? dueDate : nil)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let item = mode.existingItem {
                    title = item.title
                    details = item.details
                    if let dd = item.dueDate {
                        hasDueDate = true
                        dueDate = dd
                    } else {
                        hasDueDate = false
                        dueDate = Date()
                    }
                } else {
                    titleFocused = true
                }
            }
        }
    }
}

#Preview {
    TodoEditorView(mode: .create) { _, _, _ in }
}
