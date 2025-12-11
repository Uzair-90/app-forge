import SwiftUI

struct CalculatorSettingsView: View {
    @Binding var angleUnit: CalculatorAngleUnit

    var body: some View {
        Form {
            Section(header: Text("Angle Unit")) {
                Picker("Angle Unit", selection: $angleUnit) {
                    ForEach(CalculatorAngleUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(footer: Text("Scientific calculator demo. Angle unit affects trigonometric and inverse trigonometric functions.")) {
                EmptyView()
            }
        }
        .navigationTitle("Calculator Settings")
    }
}

struct CalculatorSettingsView_Previews: PreviewProvider {
    @State static var unit: CalculatorAngleUnit = .degrees

    static var previews: some View {
        NavigationView {
            CalculatorSettingsView(angleUnit: $unit)
        }
    }
}
