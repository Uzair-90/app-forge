import SwiftUI

struct CalculatorDisplayView: View {
    let primaryText: String
    let secondaryText: String
    let isInErrorState: Bool

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if !secondaryText.isEmpty {
                Text(secondaryText)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(Color("DisplaySecondaryText"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            Text(primaryText)
                .font(.system(size: 48, weight: .semibold, design: .rounded))
                .foregroundColor(isInErrorState ? Color("DisplayErrorText") : Color("DisplayPrimaryText"))
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .accessibilityLabel(primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color("DisplayBackground"))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
    }
}

struct CalculatorDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CalculatorDisplayView(primaryText: "42", secondaryText: "6 × 7", isInErrorState: false)
                .padding()
                .previewLayout(.sizeThatFits)

            CalculatorDisplayView(primaryText: "Error", secondaryText: "Math error", isInErrorState: true)
                .padding()
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.dark)
        }
    }
}
