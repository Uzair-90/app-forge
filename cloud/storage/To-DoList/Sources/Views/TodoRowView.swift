import SwiftUI

struct TodoRowView: View {
    let item: TodoItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(item.isCompleted ? .green : .secondary)
                    .accessibilityLabel(item.isCompleted ? "Mark as not completed" : "Mark as completed")
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                    .strikethrough(item.isCompleted, color: .secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if !item.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(item.details)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if let due = item.dueDate {
                        Label(due, systemImage: "calendar")
                            .labelStyle(.titleAndIcon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 0)

            if item.isCompleted {
                Text("Done")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.12), in: Capsule())
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

#Preview {
    List {
        TodoRowView(
            item: TodoItem(title: "Buy groceries", details: "Milk, eggs, bread", isCompleted: false, dueDate: Calendar.current.date(byAdding: .day, value: 1, to: .now)),
            onToggle: {}
        )
        TodoRowView(
            item: TodoItem(title: "Finish report", details: "Send to team", isCompleted: true, dueDate: nil),
            onToggle: {}
        )
    }
}
