import SwiftUI

// Components
import Components
import Combine

struct ContentView: View {
    @State private var selection = 0
    @StateObject private var viewModel = ContentViewModel()
    @StateObject private var notesViewModel = NotesViewModel()

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
            
            NotesListView(viewModel: notesViewModel)
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
                .tag(3)
        }
        .accentColor(.blue)
        .environmentObject(viewModel)
        .environmentObject(notesViewModel)
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 15 Pro")
            .preferredColorScheme(.light)
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