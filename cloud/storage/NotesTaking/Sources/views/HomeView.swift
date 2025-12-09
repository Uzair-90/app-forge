import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showDetail = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Text("Welcome")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "bell.fill")
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Content
                    ForEach(0..<10, id: \.self) { index in
                        CardView(title: "Item \(index)", 
                               subtitle: "Description \(index)")
                            .onTapGesture {
                                showDetail.toggle()
                            }
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showDetail) {
                DetailView()
            }
        }
    }
}

struct CardView: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}