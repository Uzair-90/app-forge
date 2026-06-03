import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    EmptyStateView(
        title: "No Tasks Yet",
        message: "Add your first to-do to get started.",
        systemImage: "checklist",
        actionTitle: "Add Task",
        action: {}
    )
}
