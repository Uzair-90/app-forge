import SwiftUI

struct TodoRowView: View {
    let item: TodoItem
    let onToggle: () -> Void

    private var dueDateText: String? {
        guard let due = item.dueDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = item.hasTime ? .short : .none
        return formatter.string(from: due)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(item.isCompleted ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.title)
                        .font(.headline)
                        .strikethrough(item.isCompleted, color: .secondary)
                        .foregroundColor(item.isCompleted ? .secondary : .primary)
                        .lineLimit(2)

                    Spacer()

                    Text(item.priority.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(priorityColor.opacity(0.12))
                        .foregroundColor(priorityColor)
                        .clipShape(Capsule())
                }

                if let dueText = dueDateText {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(dueText)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {
                    Label(item.category.displayName, systemImage: "folder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var priorityColor: Color {
        switch item.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

struct TodoRowView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TodoRowView(
                item: TodoItem(
                    title: "Buy groceries",
                    notes: "Milk, eggs, bread",
                    isCompleted: false,
                    dueDate: Date().addingTimeInterval(3600 * 5),
                    hasTime: true,
                    priority: .high,
                    category: .shopping
                ),
                onToggle: {}
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("Active")

            TodoRowView(
                item: TodoItem(
                    title: "Walk the dog",
                    notes: "",
                    isCompleted: true,
                    dueDate: nil,
                    hasTime: false,
                    priority: .low,
                    category: .personal
                ),
                onToggle: {}
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("Completed")
        }
    }
}
