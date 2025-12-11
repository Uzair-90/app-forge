import SwiftUI

struct TodoEmptyStateView: View {
    let onAddTapped: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checklist")
                .font(.system(size: 56))
                .foregroundColor(.accentColor.opacity(0.7))

            Text("No tasks yet")
                .font(.title2.bold())

            Text("Add your first task to stay on top of your day.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: onAddTapped) {
                Label("Add Task", systemImage: "plus")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.accentColor))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)

            Spacer()
        }
        .padding()
    }
}

struct TodoEmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        TodoEmptyStateView(onAddTapped: {})
    }
}
