import SwiftUI

/// Legacy detail view retained for compatibility.
/// Use `TaskDetailView` for the full task experience.
struct DetailView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.tint)
            Text("Task Details")
                .font(.title3.weight(.semibold))
            Text("This project now uses TaskDetailView.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { DetailView() }
}