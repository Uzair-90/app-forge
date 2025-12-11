import SwiftUI

struct CalculatorButtonView: View {
    let type: CalculatorButtonType
    let action: (CalculatorButtonType) -> Void

    var body: some View {
        Button(action: { action(type) }) {
            Text(type.label)
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundColor(type.foregroundColor)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(type.backgroundColor)
        .cornerRadius(12)
        .accessibilityLabel(type.accessibilityLabel)
    }
}

struct CalculatorButtonView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CalculatorButtonView(type: .digit("7"), action: { _ in })
                .frame(width: 64, height: 64)
                .padding()
                .previewLayout(.sizeThatFits)

            CalculatorButtonView(type: .operation(.add), action: { _ in })
                .frame(width: 64, height: 64)
                .padding()
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.dark)
        }
    }
}
