import SwiftUI

struct CalculatorKeypadView: View {
    let onTap: (CalculatorButtonType) -> Void

    private var memoryRow: [CalculatorButtonType] {
        [
            .memory(.mc), .memory(.mr), .memory(.mPlus), .memory(.mMinus), .memory(.ms)
        ]
    }

    private var topRow: [CalculatorButtonType] {
        [
            .clear, .plusMinus, .constant("π"), .constant("e"), .delete
        ]
    }

    private var functionRow1: [CalculatorButtonType] {
        [
            .function(.sin), .function(.cos), .function(.tan), .function(.sqrt), .function(.square)
        ]
    }

    private var functionRow2: [CalculatorButtonType] {
        [
            .function(.ln), .function(.log10), .function(.exp), .function(.factorial), .operation(.power)
        ]
    }

    private var mainKeypadRows: [[CalculatorButtonType]] {
        [
            [.digit("7"), .digit("8"), .digit("9"), .operation(.divide)],
            [.digit("4"), .digit("5"), .digit("6"), .operation(.multiply)],
            [.digit("1"), .digit("2"), .digit("3"), .operation(.subtract)],
            [.digit("0"), .decimal, .operation(.modulo), .operation(.add)]
        ]
    }

    var body: some View {
        VStack(spacing: 10) {
            keypadRow(memoryRow)
            keypadRow(topRow)
            keypadRow(functionRow1)
            keypadRow(functionRow2)

            ForEach(mainKeypadRows.indices, id: \.[self]) { index in
                let row = mainKeypadRows[index]
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { button in
                        CalculatorButtonView(type: button, action: onTap)
                            .frame(width: button.isWide ? 2 * 64 + 10 : 64, height: 64)
                    }

                    if index == mainKeypadRows.count - 1 {
                        CalculatorButtonView(type: .equals, action: onTap)
                            .frame(width: 64, height: 64 * 2 + 10)
                            .background(Color.clear)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func keypadRow(_ row: [CalculatorButtonType]) -> some View {
        HStack(spacing: 10) {
            ForEach(row, id: \.self) { button in
                CalculatorButtonView(type: button, action: onTap)
                    .frame(height: 40)
            }
        }
    }
}

struct CalculatorKeypadView_Previews: PreviewProvider {
    static var previews: some View {
        CalculatorKeypadView(onTap: { _ in })
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
