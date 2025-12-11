import SwiftUI

// Components
import Components

struct ContentView: View {
    var body: some View {
        ScientificCalculatorView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ExploreView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Explore")
                    .font(.largeTitle)
                    .bold()
                
                Text("Discover new content here!")
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Explore")
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var viewModel: ContentViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.blue)
                
                Text("Your Profile")
                    .font(.largeTitle)
                    .bold()
                
                Text("Manage your account and settings")
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
        }
    }
}