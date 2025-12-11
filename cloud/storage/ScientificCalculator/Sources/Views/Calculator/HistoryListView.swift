import SwiftUI

struct HistoryListView: View {
    let items: [CalculationHistoryItem]
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("History")
                    .font(.headline)
                Spacer()
                if !items.isEmpty {
                    Button("Clear") { onClear() }
                        .font(.subheadline)
                        .foregroundColor(Color.accentColor)
                }
            }

            if items.isEmpty {
                Text("No recent calculations")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(items) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.expression)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                Text("= \(item.result)")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                            .padding(10)
                            .background(Color("HistoryItemBackground"))
                            .cornerRadius(10)
                        }
                    }
                }
                .frame(height: 64)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

struct HistoryListView_Previews: PreviewProvider {
    static var previews: some View {
        let sample = [
            CalculationHistoryItem(id: UUID(), expression: "6 × 7", result: "42", timestamp: Date()),
            CalculationHistoryItem(id: UUID(), expression: "sin(30)", result: "0.5", timestamp: Date())
        ]
        return HistoryListView(items: sample, onClear: {})
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
