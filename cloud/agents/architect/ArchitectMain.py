import json
import os
from openai import OpenAI
from dotenv import load_dotenv
from typing import Dict, Any

from agents.BaseAgent import BaseAgent

load_dotenv()


class ArchitectMain(BaseAgent):
    """
    Architect Agent for iOS projects:
        - Reads user request for iOS app
        - Generates JSON project definition from LLM
        - Creates iOS project folder structure matching the exact example
        - Writes files using BaseAgent utilities
        - Updates metadata.json for tracking
    """

    def __init__(self, storage_path: str = "storage/"):
        super().__init__("ArchitectAgent", storage_path)
        self.client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

    # ------------------------------
    # LLM CALL
    # ------------------------------
    def ask_llm(self, query: str) -> Dict[str, Any]:
        """Calls the LLM to extract project structure info."""

        system_prompt = """
        You are an expert iOS Project Architect AI.
        Your job is to read the user's request for an iOS application and generate a JSON structure.

        Return ONLY valid JSON with fields:
        - app_name (string, required): The name of the iOS application
        - description (string): Brief description of the app
        - deployment_target (string): iOS deployment target (e.g., "16.0")
        - uses_swiftui (boolean): Whether the app uses SwiftUI (true for modern iOS apps)
        - features (array of strings): Key features/modules needed
        - color_scheme (string): Primary color for the app (e.g., "blue", "green", "purple")

        NEVER include explanations, only JSON.
        """

        response = self.client.chat.completions.create(
            model="gpt-4",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": query}
            ]
        )

        content = response.choices[0].message.content
        return json.loads(content)

    # ------------------------------
    # FILE GENERATION LOGIC
    # ------------------------------
    def generate_ios_structure(self, app_name: str, llm_result: Dict[str, Any]) -> Dict[str, dict]:
        """Creates iOS project folder structure & files matching the exact example provided."""

        clean_name = app_name.replace(" ", "")
        
        # Create the exact structure from your example
        dirs = [
            f"{clean_name}/Resources",
            f"{clean_name}/Sources",
            f"{clean_name}/Sources/Extensions",
            f"{clean_name}/Sources/Models",
            f"{clean_name}/Sources/views",
            f"{clean_name}/Tests"
        ]

        for d in dirs:
            os.makedirs(self.storage_path / d, exist_ok=True)

        file_changes = {}

        # --------------------
        # 1. Info.plist
        # --------------------
        info_plist_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>{app_name}</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.{clean_name}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
        <key>UISceneConfigurations</key>
        <dict>
            <key>UIWindowSceneSessionRoleApplication</key>
            <array>
                <dict>
                    <key>UISceneConfigurationName</key>
                    <string>Default Configuration</string>
                    <key>UISceneDelegateClassName</key>
                    <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
                </dict>
            </array>
        </dict>
    </dict>
    <key>UIApplicationSupportsIndirectInputEvents</key>
    <true/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
</dict>
</plist>"""
        
        rel_path = f"{clean_name}/Resources/Info.plist"
        self.write_file(rel_path, info_plist_content)
        file_changes[rel_path] = {"type": "generated"}

        # --------------------
        # 2. AppDelegate.swift
        # --------------------
        app_delegate_content = """import UIKit
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // App configuration
        print("App launched!")
        return true
    }
    
    func application(_ application: UIApplication, 
                    configurationForConnecting connectingSceneSession: UISceneSession,
                    options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
}
"""
        
        rel_path = f"{clean_name}/Sources/AppDelegate.swift"
        self.write_file(rel_path, app_delegate_content)
        file_changes[rel_path] = {"type": "generated"}

        # --------------------
        # 3. AppMain.swift
        # --------------------
        app_main_content = """import SwiftUI

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    // Initial setup
                    setupAppearance()
                }
                .preferredColorScheme(.light) // or .dark, or nil for system
        }
    }
    
    private func setupAppearance() {
        // Customize navigation bar
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}"""
        
        rel_path = f"{clean_name}/Sources/AppMain.swift"
        self.write_file(rel_path, app_main_content)
        file_changes[rel_path] = {"type": "generated"}

        # --------------------
        # 4. ContentView.swift
        # --------------------
        color_scheme = llm_result.get('color_scheme', 'blue').capitalize()
        content_view_content = f"""import SwiftUI

struct ContentView: View {{
    @State private var selection = 0
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {{
        TabView(selection: $selection) {{
            HomeView()
                .tabItem {{
                    Label("Home", systemImage: "house.fill")
                }}
                .tag(0)
            
            ExploreView()
                .tabItem {{
                    Label("Explore", systemImage: "magnifyingglass")
                }}
                .tag(1)
            
            ProfileView()
                .tabItem {{
                    Label("Profile", systemImage: "person.fill")
                }}
                .tag(2)
        }}
        .accentColor(.blue)
        .environmentObject(viewModel)
    }}
}}

// Preview
struct ContentView_Previews: PreviewProvider {{
    static var previews: some View {{
        ContentView()
            .previewDevice("iPhone 15 Pro")
            .preferredColorScheme(.light)
    }}
}}

struct ExploreView: View {{
    var body: some View {{
        NavigationView {{
            VStack(spacing: 20) {{
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Explore")
                    .font(.largeTitle)
                    .bold()
                
                Text("Discover new content here!")
                    .foregroundColor(.gray)
                
                Spacer()
            }}
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Explore")
        }}
    }}
}}

// MARK: - Profile View
struct ProfileView: View {{
    @EnvironmentObject var viewModel: ContentViewModel
    
    var body: some View {{
        NavigationView {{
            VStack(spacing: 20) {{
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
            }}
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
        }}
    }}
}}"""
        
        rel_path = f"{clean_name}/Sources/ContentView.swift"
        self.write_file(rel_path, content_view_content)
        file_changes[rel_path] = {"type": "generated"}

        # --------------------
        # 5. View+Extensions.swift
        # --------------------
        view_extensions_content = """import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                       to: nil, from: nil, for: nil)
    }
    
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
    
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect, 
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}"""
        
        rel_path = f"{clean_name}/Sources/Extensions/View+Extensions.swift"
        self.write_file(rel_path, view_extensions_content)
        file_changes[rel_path] = {"type": "generated"}

        # --------------------
        # 6. AppState.swift
        # --------------------
        app_state_content = """import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var user: Bool = false
    @Published var isLoading: Bool = false
}

class ContentViewModel: ObservableObject {
    @Published var items: [String] = []
    @Published var error: Error?
    
    func loadData() async {
        // Async data loading
    }
}"""
        
        rel_path = f"{clean_name}/Sources/Models/AppState.swift"
        self.write_file(rel_path, app_state_content)
        file_changes[rel_path] = {"type": "generated"}

        # --------------------
        # 7. SceneDelegate.swift
        # --------------------
        scene_delegate_content = """import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, 
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        let window = UIWindow(windowScene: windowScene)
        let contentView = ContentView()
            .environmentObject(AppState())
        
        window.rootViewController = UIHostingController(rootView: contentView)
        self.window = window
        window.makeKeyAndVisible()
    }
}
"""
        
        rel_path = f"{clean_name}/Sources/SceneDelegate.swift"
        self.write_file(rel_path, scene_delegate_content)
        file_changes[rel_path] = {"type": "generated"}

        # --------------------
        # 8. HomeView.swift
        # --------------------
        home_view_content = """import SwiftUI

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
                    ForEach(0..<10, id: \\.self) { index in
                        CardView(title: "Item \\(index)", 
                               subtitle: "Description \\(index)")
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
}"""
        
        rel_path = f"{clean_name}/Sources/views/HomeView.swift"
        self.write_file(rel_path, home_view_content)
        file_changes[rel_path] = {"type": "generated"}

        # --------------------
        # 9. DetailView.swift
        # --------------------
        detail_view_content = """import SwiftUI

struct DetailView: View {
    @Environment(\\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // Image placeholder
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                    )
                    .padding(.top)
                
                // Title
                Text("Detail View")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Description
                Text("Here you can show the details of the selected item. Add more content like images, text, or actions.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                    }
                }
            }
        }
    }
}"""
        
        rel_path = f"{clean_name}/Sources/views/DetailView.swift"
        self.write_file(rel_path, detail_view_content)
        file_changes[rel_path] = {"type": "generated"}

        # --------------------
        # 10. project.yml
        # --------------------
        deployment_target = llm_result.get('deployment_target', '16.0')
        project_yml_content = f"""name: {clean_name}
options:
  bundleIdPrefix: com.example
  deploymentTarget:
    iOS: "{deployment_target}"
  xcodeVersion: "15.0"
targets:
  {clean_name}:
    type: application
    platform: iOS
    sources:
      - path: Sources
      - path: Resources
        type: resource
    info:
      path: Resources/Info.plist
      properties:
        CFBundleDisplayName: {app_name}
        UILaunchStoryboardName: LaunchScreen
        UIApplicationSceneManifest:
          UIApplicationSupportsMultipleScenes: false
          UISceneConfigurations:
            UIWindowSceneSessionRoleApplication:
              - UISceneConfigurationName: Default Configuration
                UISceneDelegateClassName: "$(PRODUCT_MODULE_NAME).SceneDelegate"
    settings:
      base:
        PRODUCT_NAME: {clean_name}
        TARGETED_DEVICE_FAMILY: 1,2
        IPHONEOS_DEPLOYMENT_TARGET: {deployment_target}
        CODE_SIGN_STYLE: Automatic
        DEVELOPMENT_TEAM: ""
    dependencies:
      - sdk: SwiftUI.framework
      - sdk: UIKit.framework
schemes:
  {clean_name}:
    build:
      targets:
        {clean_name}: all
    run:
      config: Debug
      executable: {clean_name}
    test:
      config: Debug
      gatherCoverageData: true"""
        
        rel_path = f"{clean_name}/project.yml"
        self.write_file(rel_path, project_yml_content)
        file_changes[rel_path] = {"type": "generated"}

        return file_changes

    # ------------------------------
    # CORE METHOD REQUIRED BY BaseAgent
    # ------------------------------
    def perform_task(self, prompt: str, metadata: Dict[str, Any] = None) -> Dict[str, Any]:
        """
        Main entry for the architect agent.
        1. Ask LLM for project structure
        2. Generate iOS project
        3. Update metadata.json
        """

        self.log("Received new request. Querying LLM...")
        result = self.ask_llm(prompt)

        app_name = result["app_name"]
        self.log(f"Creating iOS project for: {app_name}")

        file_changes = self.generate_ios_structure(app_name, result)

        updated_metadata = self.update_metadata(file_changes)

        return {
            "app_name": app_name,
            "llm_result": result,
            "file_changes": file_changes,
            "metadata": updated_metadata
        }