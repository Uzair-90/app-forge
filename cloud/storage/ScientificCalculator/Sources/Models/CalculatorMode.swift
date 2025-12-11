import Foundation

enum CalculatorAngleUnit: String, CaseIterable, Identifiable {
    case degrees = "Degrees"
    case radians = "Radians"

    var id: String { rawValue }
}

enum CalculatorTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }
}
