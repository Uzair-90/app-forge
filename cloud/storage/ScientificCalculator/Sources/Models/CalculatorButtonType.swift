import Foundation
import SwiftUI

enum CalculatorButtonType: Hashable, Identifiable {
    case digit(String)
    case decimal
    case constant(String)
    case operation(OperationType)
    case function(FunctionType)
    case memory(MemoryType)
    case clear
    case delete
    case plusMinus
    case equals
    case empty

    var id: String { label }

    enum OperationType: String, CaseIterable {
        case add = "+"
        case subtract = "−"
        case multiply = "×"
        case divide = "÷"
        case power = "xʸ"
        case modulo = "mod"
    }

    enum FunctionType: String, CaseIterable {
        case sin, cos, tan
        case asin, acos, atan
        case ln, log10
        case sqrt, square
        case exp
        case factorial
    }

    enum MemoryType: String, CaseIterable {
        case mc = "MC"
        case mr = "MR"
        case mPlus = "M+"
        case mMinus = "M-"
        case ms = "MS"
    }

    var label: String {
        switch self {
        case .digit(let value): return value
        case .decimal: return "."
        case .constant(let value): return value
        case .operation(let op): return op.rawValue
        case .function(let fn): return fn.rawValue
        case .memory(let mem): return mem.rawValue
        case .clear: return "AC"
        case .delete: return "⌫"
        case .plusMinus: return "±"
        case .equals: return "="
        case .empty: return ""
        }
    }

    var backgroundColor: Color {
        switch self {
        case .digit, .decimal:
            return Color("KeypadDigitBackground")
        case .operation, .plusMinus, .equals:
            return Color("KeypadOperationBackground")
        case .function, .constant:
            return Color("KeypadFunctionBackground")
        case .memory:
            return Color("KeypadMemoryBackground")
        case .clear, .delete:
            return Color("KeypadUtilityBackground")
        case .empty:
            return .clear
        }
    }

    var foregroundColor: Color {
        switch self {
        case .digit, .decimal:
            return Color("KeypadDigitForeground")
        case .operation, .plusMinus, .equals:
            return Color("KeypadOperationForeground")
        case .function, .constant:
            return Color("KeypadFunctionForeground")
        case .memory:
            return Color("KeypadMemoryForeground")
        case .clear, .delete:
            return Color("KeypadUtilityForeground")
        case .empty:
            return .clear
        }
    }

    var isWide: Bool {
        if case .digit("0") = self { return true }
        return false
    }

    var accessibilityLabel: String {
        switch self {
        case .digit(let value): return value
        case .decimal: return "decimal"
        case .constant(let value): return value
        case .operation(let op): return op.rawValue
        case .function(let fn): return fn.rawValue
        case .memory(let mem): return mem.rawValue
        case .clear: return "clear"
        case .delete: return "delete"
        case .plusMinus: return "plus minus"
        case .equals: return "equals"
        case .empty: return ""
        }
    }
}
