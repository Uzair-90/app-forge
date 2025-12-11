import Foundation
import Combine

final class ScientificCalculatorViewModel: ObservableObject {
    // MARK: - Published State
    @Published var display: String = "0"
    @Published var secondaryDisplay: String = ""
    @Published var isInErrorState: Bool = false
    @Published var memoryStored: Double? = nil
    @Published var angleUnit: CalculatorAngleUnit = .degrees

    // For history
    @Published var history: [CalculationHistoryItem] = []

    // Internal
    private var currentValue: Double = 0
    private var pendingOperation: CalculatorButtonType.OperationType? = nil
    private var isTypingNumber: Bool = false
    private var lastInputWasEquals: Bool = false

    // MARK: - Public Intent
    func handleButtonTap(_ button: CalculatorButtonType) {
        isInErrorState = false

        switch button {
        case .digit(let value):
            handleDigit(value)
        case .decimal:
            handleDecimal()
        case .constant(let value):
            handleConstant(value)
        case .operation(let op):
            handleOperation(op)
        case .function(let fn):
            handleFunction(fn)
        case .memory(let mem):
            handleMemory(mem)
        case .clear:
            clearAll()
        case .delete:
            deleteLast()
        case .plusMinus:
            toggleSign()
        case .equals:
            evaluateEquals()
        case .empty:
            break
        }
    }

    func clearHistory() {
        history.removeAll()
    }

    // MARK: - Private helpers
    private func handleDigit(_ digit: String) {
        if lastInputWasEquals {
            currentValue = 0
            pendingOperation = nil
            secondaryDisplay = ""
            lastInputWasEquals = false
        }

        if isTypingNumber {
            if display == "0" {
                display = digit
            } else {
                display.append(digit)
            }
        } else {
            display = digit
            isTypingNumber = true
        }
    }

    private func handleDecimal() {
        if !isTypingNumber {
            display = "0."
            isTypingNumber = true
        } else if !display.contains(".") {
            display.append(".")
        }
    }

    private func handleConstant(_ value: String) {
        let constantValue: Double
        switch value {
        case "π":
            constantValue = Double.pi
        case "e":
            constantValue = M_E
        default:
            constantValue = 0
        }
        display = formatted(constantValue)
        isTypingNumber = false
    }

    private func handleOperation(_ op: CalculatorButtonType.OperationType) {
        let operand = Double(display) ?? 0

        if pendingOperation == nil || !isTypingNumber {
            currentValue = operand
        } else {
            currentValue = performOperation(pendingOperation!, currentValue, operand)
            display = formatted(currentValue)
        }

        pendingOperation = op
        isTypingNumber = false
        lastInputWasEquals = false
        secondaryDisplay = "\(formatted(currentValue)) \(op.rawValue)"
    }

    private func handleFunction(_ fn: CalculatorButtonType.FunctionType) {
        let operand = Double(display) ?? 0
        let result: Double

        switch fn {
        case .sin:
            result = trig(sin, operand)
        case .cos:
            result = trig(cos, operand)
        case .tan:
            result = trig(tan, operand)
        case .asin:
            result = invTrig(asin, operand)
        case .acos:
            result = invTrig(acos, operand)
        case .atan:
            result = invTrig(atan, operand)
        case .ln:
            if operand <= 0 { return setErrorState("Domain error") }
            result = log(operand)
        case .log10:
            if operand <= 0 { return setErrorState("Domain error") }
            result = log10(operand)
        case .sqrt:
            if operand < 0 { return setErrorState("Domain error") }
            result = sqrt(operand)
        case .square:
            result = operand * operand
        case .exp:
            result = exp(operand)
        case .factorial:
            if operand < 0 || operand.rounded() != operand { return setErrorState("Domain error") }
            result = factorial(of: Int(operand))
        }

        let expression = "\(fn.rawValue)(\(formatted(operand)))"
        addToHistory(expression: expression, result: result)
        display = formatted(result)
        secondaryDisplay = expression
        isTypingNumber = false
        lastInputWasEquals = true
    }

    private func handleMemory(_ mem: CalculatorButtonType.MemoryType) {
        let value = Double(display) ?? 0
        switch mem {
        case .mc:
            memoryStored = nil
        case .mr:
            if let stored = memoryStored {
                display = formatted(stored)
                isTypingNumber = false
            }
        case .mPlus:
            memoryStored = (memoryStored ?? 0) + value
        case .mMinus:
            memoryStored = (memoryStored ?? 0) - value
        case .ms:
            memoryStored = value
        }
    }

    private func clearAll() {
        display = "0"
        secondaryDisplay = ""
        isInErrorState = false
        currentValue = 0
        pendingOperation = nil
        isTypingNumber = false
        lastInputWasEquals = false
    }

    private func deleteLast() {
        guard isTypingNumber else { return }
        guard !display.isEmpty else { return }
        display.removeLast()
        if display.isEmpty || display == "-" {
            display = "0"
            isTypingNumber = false
        }
    }

    private func toggleSign() {
        guard display != "0" else { return }
        if display.hasPrefix("-") {
            display.removeFirst()
        } else {
            display = "-" + display
        }
    }

    private func evaluateEquals() {
        let operand = Double(display) ?? 0
        guard let op = pendingOperation else { return }

        let result = performOperation(op, currentValue, operand)
        let expression = "\(formatted(currentValue)) \(op.rawValue) \(formatted(operand))"

        addToHistory(expression: expression, result: result)
        display = formatted(result)
        secondaryDisplay = expression
        currentValue = result
        isTypingNumber = false
        pendingOperation = nil
        lastInputWasEquals = true
    }

    private func performOperation(_ op: CalculatorButtonType.OperationType, _ lhs: Double, _ rhs: Double) -> Double {
        switch op {
        case .add: return lhs + rhs
        case .subtract: return lhs - rhs
        case .multiply: return lhs * rhs
        case .divide: return rhs == 0 ? Double.nan : lhs / rhs
        case .power: return pow(lhs, rhs)
        case .modulo: return rhs == 0 ? Double.nan : lhs.truncatingRemainder(dividingBy: rhs)
        }
    }

    private func trig(_ fn: (Double) -> Double, _ value: Double) -> Double {
        let radians: Double
        switch angleUnit {
        case .degrees:
            radians = value * .pi / 180
        case .radians:
            radians = value
        }
        return fn(radians)
    }

    private func invTrig(_ fn: (Double) -> Double, _ value: Double) -> Double {
        let result = fn(value)
        switch angleUnit {
        case .degrees:
            return result * 180 / .pi
        case .radians:
            return result
        }
    }

    private func factorial(of n: Int) -> Double {
        if n == 0 { return 1 }
        return (1...n).map(Double.init).reduce(1, *)
    }

    private func formatted(_ value: Double) -> String {
        if value.isNaN || value.isInfinite {
            setErrorState("Math error")
            return "Error"
        }
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 8
        formatter.minimumFractionDigits = 0
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    private func setErrorState(_ message: String) {
        isInErrorState = true
        display = "Error"
        secondaryDisplay = message
        isTypingNumber = false
        pendingOperation = nil
        lastInputWasEquals = true
    }

    private func addToHistory(expression: String, result: Double) {
        let item = CalculationHistoryItem(
            id: UUID(),
            expression: expression,
            result: formatted(result),
            timestamp: Date()
        )
        history.insert(item, at: 0)
    }
}

struct CalculationHistoryItem: Identifiable, Hashable {
    let id: UUID
    let expression: String
    let result: String
    let timestamp: Date
}
