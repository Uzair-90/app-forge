import SwiftUI

struct ScientificCalculatorView: View {
    @StateObject private var viewModel = ScientificCalculatorViewModel()
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                CalculatorDisplayView(
                    primaryText: viewModel.display,
                    secondaryText: viewModel.secondaryDisplay,
                    isInErrorState: viewModel.isInErrorState
                )
                .padding(.top, 8)

                HistoryListView(items: viewModel.history, onClear: viewModel.clearHistory)

                Spacer(minLength: 8)

                CalculatorKeypadView(onTap: viewModel.handleButtonTap)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
            }
            .background(Color("AppBackground").ignoresSafeArea())
            .navigationTitle("Scientific Calculator")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings.toggle() }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationView {
                    CalculatorSettingsView(angleUnit: $viewModel.angleUnit)
                }
            }
        }
    }
}

struct ScientificCalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        ScientificCalculatorView()
            .preferredColorScheme(.dark)

        ScientificCalculatorView()
            .preferredColorScheme(.light)
    }
}
