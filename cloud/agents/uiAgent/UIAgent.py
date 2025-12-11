import json
import os
from openai import OpenAI
from dotenv import load_dotenv
from typing import Dict, Any, List
from pathlib import Path

from agents.BaseAgent import BaseAgent

load_dotenv()


class UIModelAgent(BaseAgent):
    """
    UI Model Agent for iOS projects:
        - Takes user request and metadata.json from ArchitectMain phase
        - Creates additional UI components, models, and views
        - Updates existing files with necessary imports and modifications
        - Maintains consistency with project structure
    """

    def __init__(self, storage_path: str = "storage/"):
        super().__init__("UIModelAgent", storage_path)
        self.client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        self.metadata = None
        self.project_root = None
        self.app_name = None
        self.clean_name = None

    # ------------------------------
    # METADATA & PROJECT SETUP
    # ------------------------------
    def load_metadata(self) -> Dict[str, Any]:
        """Load metadata.json from storage."""
        metadata_path = self.storage_path / "metadata.json"
        if not metadata_path.exists():
            raise FileNotFoundError(f"metadata.json not found at {metadata_path}")
        
        with open(metadata_path, "r") as f:
            metadata = json.load(f)
        
        self.metadata = metadata
        
        # Check if metadata is in the old format (flat dictionary)
        # or new format (with phases array)
        if "phases" in metadata:
            # New format: look for ArchitectAgent phase
            architect_phase = None
            for phase in reversed(metadata.get("phases", [])):
                if phase.get("agent") == "ArchitectAgent":
                    architect_phase = phase
                    break
            
            if not architect_phase:
                raise ValueError("No ArchitectAgent phase found in metadata")
            
            # Get app_name from results
            results = architect_phase.get("results", {})
            self.app_name = results.get("app_name", "MyApp")
            
        else:
            # OLD FORMAT: metadata is a flat dictionary of file changes
            # Extract app name from file paths
            # Find all unique app names (first part of path before /)
            app_names = set()
            for file_path in metadata.keys():
                parts = file_path.split('/')
                if parts:  # Make sure we have at least one part
                    app_names.add(parts[0])
            
            if not app_names:
                raise ValueError("Could not determine app name from metadata")
            
            # Use the most recent app (last one in the dictionary)
            # Or you could use the first one
            last_file = list(metadata.keys())[-1]
            self.app_name = last_file.split('/')[0]
        
        self.clean_name = self.app_name.replace(" ", "")
        self.project_root = self.storage_path / self.clean_name
        
        return metadata

    def get_existing_files(self) -> List[str]:
        """Get list of existing Swift files in the project."""
        swift_files = []
        for root, dirs, files in os.walk(self.project_root):
            for file in files:
                if file.endswith(".swift"):
                    # Get path relative to project root
                    rel_path = Path(root) / file
                    project_relative_path = rel_path.relative_to(self.project_root)
                    swift_files.append(str(project_relative_path))
        return swift_files

    # ------------------------------
    # LLM CALLS
    # ------------------------------
    def ask_llm_for_ui_components(self, query: str, existing_files: List[str]) -> Dict[str, Any]:
        """Calls the LLM to design UI components and models."""

        system_prompt = """
        You are an expert iOS UI/UX Designer and Swift Developer.
        Your job is to create additional UI components, data models, and view models based on user requirements.

        The user will provide:
        1. Their requirements for additional features/UI
        2. List of existing Swift files in the project (to avoid duplication)

        You MUST return ONLY valid JSON with the following structure:
        {
            "new_files": [
                {
                    "path": "relative/path/to/file.swift",
                    "type": "view|model|viewmodel|extension|utility",
                    "content": "Full Swift code content"
                }
            ],
            "modifications": [
                {
                    "file": "relative/path/to/existing/file.swift",
                    "changes": [
                        {
                            "type": "import|class|struct|function|property",
                            "action": "add|modify|remove",
                            "content": "Code to add or modify"
                        }
                    ]
                }
            ],
            "color_scheme_updates": {
                "primary_color": "ColorName",
                "secondary_color": "ColorName",
                "accent_color": "ColorName"
            }
        }

        IMPORTANT RULES:
        1. Paths should be relative to the project root (e.g., "Sources/Views/NewView.swift")
        2. Never duplicate existing files
        3. Follow Swift best practices and naming conventions
        4. Use SwiftUI for views (unless UIKit is explicitly required)
        5. Make sure to include proper imports
        6. Add preview providers for views
        7. Use ObservableObject for view models
        8. Follow MVVM architecture pattern
        """

        existing_files_str = "\n".join(existing_files)

        response = self.client.chat.completions.create(
            model="gpt-5.1",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"Requirements: {query}\n\nExisting files:\n{existing_files_str}"}
            ]
        )

        content = response.choices[0].message.content
        return json.loads(content)

    def ask_llm_for_content_update(self, file_path: str, current_content: str, requirements: str) -> str:
        """Ask LLM to update existing file content."""
        
        system_prompt = """
        You are an expert Swift developer. Update the given Swift file based on the requirements.
        Return ONLY the complete updated Swift code, no explanations.
        Maintain the existing structure and style.
        Add proper imports if needed.
        """
        
        response = self.client.chat.completions.create(
            model="gpt-5.1",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"File: {file_path}\n\nCurrent content:\n{current_content}\n\nRequirements: {requirements}"}
            ]
        )
        
        return response.choices[0].message.content

    # ------------------------------
    # FILE OPERATIONS
    # ------------------------------
    def create_new_files(self, new_files: List[Dict[str, Any]]) -> Dict[str, dict]:
        """Create new Swift files."""
        file_changes = {}
        
        for file_info in new_files:
            project_relative_path = file_info["path"]  # e.g., "Sources/Models/User.swift"
            content = file_info["content"]
            file_type = file_info.get("type", "view")
            
            # Convert to storage path: storage/{clean_name}/{project_relative_path}
            storage_relative_path = f"{self.clean_name}/{project_relative_path}"
            full_path = self.storage_path / storage_relative_path
            
            # Create directory if it doesn't exist
            full_path.parent.mkdir(parents=True, exist_ok=True)
            
            # Write file
            self.write_file(storage_relative_path, content)
            file_changes[storage_relative_path] = {"type": "created", "file_type": file_type}
            
            self.log(f"Created {file_type}: {storage_relative_path}")
        
        return file_changes

    def modify_existing_files(self, modifications: List[Dict[str, Any]]) -> Dict[str, dict]:
        """Modify existing Swift files."""
        file_changes = {}
        
        for mod_info in modifications:
            project_relative_path = mod_info["file"]  # e.g., "Sources/ContentView.swift"
            
            # Convert to storage path
            storage_relative_path = f"{self.clean_name}/{project_relative_path}"
            full_path = self.storage_path / storage_relative_path
            
            if not full_path.exists():
                self.log(f"Warning: File {storage_relative_path} doesn't exist, skipping modifications")
                continue
            
            # Read current content
            with open(full_path, "r") as f:
                current_content = f.read()
            
            # For now, we'll use LLM to update the file
            requirements = f"Apply these changes: {json.dumps(mod_info['changes'])}"
            updated_content = self.ask_llm_for_content_update(project_relative_path, current_content, requirements)
            
            # Write updated content
            self.write_file(storage_relative_path, updated_content)
            file_changes[storage_relative_path] = {"type": "modified", "changes": len(mod_info["changes"])}
            
            self.log(f"Modified: {storage_relative_path}")
        
        return file_changes

    def create_color_assets(self, color_scheme: Dict[str, str]) -> Dict[str, dict]:
        """Create color assets for the app."""
        file_changes = {}
        
        # Create Colors.swift file
        colors_content = """import SwiftUI

extension Color {
    // MARK: - App Colors
    
    static let primaryColor = Color("PrimaryColor")
    static let secondaryColor = Color("SecondaryColor")
    static let accentColor = Color("AccentColor")
    static let backgroundColor = Color("BackgroundColor")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    
    // MARK: - Semantic Colors
    
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
    
    // MARK: - Utility Colors
    
    static let lightGray = Color(hex: "F5F5F5")
    static let mediumGray = Color(hex: "E0E0E0")
    static let darkGray = Color(hex: "616161")
    
    // MARK: - Gradient Presets
    
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [.primaryColor, .accentColor]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
"""
        
        colors_path = f"{self.clean_name}/Sources/Extensions/Colors.swift"
        self.write_file(colors_path, colors_content)
        file_changes[colors_path] = {"type": "created", "file_type": "extension"}
        
        # Create Assets.xcassets directory structure
        assets_dir = self.project_root / "Resources" / "Assets.xcassets"
        assets_dir.mkdir(parents=True, exist_ok=True)
        
        # Create Contents.json for Assets.xcassets
        contents_json = {
            "info": {
                "version": 1,
                "author": "xcode"
            }
        }
        
        with open(assets_dir / "Contents.json", "w") as f:
            json.dump(contents_json, f, indent=2)
        
        # Create color assets
        colors = {
            "PrimaryColor": color_scheme.get("primary_color", "007AFF"),
            "SecondaryColor": color_scheme.get("secondary_color", "5856D6"),
            "AccentColor": color_scheme.get("accent_color", "FF9500"),
            "BackgroundColor": "FFFFFF",
            "TextPrimary": "000000",
            "TextSecondary": "8E8E93"
        }
        
        for color_name, hex_value in colors.items():
            color_dir = assets_dir / f"{color_name}.colorset"
            color_dir.mkdir(exist_ok=True)
            
            color_contents = {
                "colors": [
                    {
                        "color": {
                            "color-space": "srgb",
                            "components": {
                                "red": f"0x{hex_value[0:2]}",
                                "green": f"0x{hex_value[2:4]}",
                                "blue": f"0x{hex_value[4:6]}",
                                "alpha": "1.000"
                            }
                        },
                        "idiom": "universal"
                    }
                ],
                "info": {
                    "version": 1,
                    "author": "xcode"
                }
            }
            
            with open(color_dir / "Contents.json", "w") as f:
                json.dump(color_contents, f, indent=2)
        
        self.log("Created color assets")
        
        return file_changes

    # ------------------------------
    # COMMON UI COMPONENT GENERATORS
    # ------------------------------
    def create_common_components(self) -> Dict[str, dict]:
        """Create common UI components that every app might need."""
        file_changes = {}
        
        components = [
            {
                "project_path": "Sources/Components/ButtonStyles.swift",
                "content": """import SwiftUI

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? Color.primaryColor : Color.gray)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.primaryColor)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primaryColor, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct IconButtonStyle: ButtonStyle {
    let size: CGFloat
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(configuration.isPressed ? Color.primaryColor.opacity(0.1) : Color.clear)
            .cornerRadius(size / 2)
    }
}

// MARK: - Button View Modifiers
extension View {
    func primaryButton(isEnabled: Bool = true) -> some View {
        self.buttonStyle(PrimaryButtonStyle(isEnabled: isEnabled))
    }
    
    func secondaryButton() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
    
    func iconButton(size: CGFloat = 44) -> some View {
        self.buttonStyle(IconButtonStyle(size: size))
    }
}
"""
            },
            {
                "project_path": "Sources/Components/Cards.swift",
                "content": """import SwiftUI

// MARK: - Card View
struct CardView<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    var backgroundColor: Color = .white
    var cornerRadius: CGFloat = 16
    var shadowColor: Color = .black.opacity(0.1)
    var shadowRadius: CGFloat = 8
    
    init(padding: CGFloat = 16,
         backgroundColor: Color = .white,
         cornerRadius: CGFloat = 16,
         shadowColor: Color = .black.opacity(0.1),
         shadowRadius: CGFloat = 8,
         @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 4)
    }
}

// MARK: - Card Preview
struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Card Title")
                    .font(.title2)
                    .bold()
                
                Text("This is a sample card with some content. Cards are great for displaying related information in a contained manner.")
                    .font(.body)
                    .foregroundColor(.gray)
                
                HStack {
                    Spacer()
                    Text("Footer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
"""
            },
            {
                "project_path": "Sources/Components/LoadingViews.swift",
                "content": """import SwiftUI

// MARK: - Loading Views
struct LoadingView: View {
    var message: String = "Loading..."
    var size: CGFloat = 50
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .primaryColor))
                .frame(width: size, height: size)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct SkeletonView: View {
    var cornerRadius: CGFloat = 8
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.3))
            .shimmering()
    }
}

// MARK: - Shimmer Effect
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .modifier(Shimmer(phase: phase))
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

struct Shimmer: AnimatableModifier {
    var phase: CGFloat
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .mask(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: phase - 0.3),
                        .init(color: .black, location: phase - 0.2),
                        .init(color: .black, location: phase - 0.1),
                        .init(color: .clear, location: phase)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
}

extension View {
    func shimmering() -> some View {
        self.modifier(ShimmerEffect())
    }
}

// MARK: - Preview
struct LoadingViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoadingView()
                .previewLayout(.sizeThatFits)
                .frame(height: 200)
            
            SkeletonView()
                .frame(height: 100)
                .padding()
                .previewLayout(.sizeThatFits)
        }
    }
}
"""
            }
        ]
        
        # Create Components directory
        components_dir = self.project_root / "Sources" / "Components"
        components_dir.mkdir(exist_ok=True)
        
        # Create component files
        for component in components:
            project_path = component["project_path"]
            storage_path = f"{self.clean_name}/{project_path}"
            content = component["content"]
            
            self.write_file(storage_path, content)
            file_changes[storage_path] = {"type": "created", "file_type": "component"}
        
        return file_changes

    # ------------------------------
    # UPDATE EXISTING FILES WITH IMPORTS
    # ------------------------------
    def update_main_files_with_imports(self) -> Dict[str, dict]:
        """Update main files to import and use new components."""
        file_changes = {}
        
        # Update ContentView.swift to use new components
        content_view_path = self.project_root / "Sources" / "ContentView.swift"
        if content_view_path.exists():
            with open(content_view_path, "r") as f:
                content = f.read()
            
            # Add import for Components if not present
            if "import SwiftUI" in content and "Components" not in content:
                # Find where to insert after SwiftUI import
                lines = content.split('\n')
                updated_lines = []
                for line in lines:
                    updated_lines.append(line)
                    if line.strip() == "import SwiftUI":
                        updated_lines.append("")
                        updated_lines.append("// Components")
                        updated_lines.append("import Components")
                
                updated_content = '\n'.join(updated_lines)
                
                # Write back using storage path
                storage_path = f"{self.clean_name}/Sources/ContentView.swift"
                self.write_file(storage_path, updated_content)
                file_changes[storage_path] = {"type": "modified", "changes": "added component imports"}
        
        return file_changes

    # ------------------------------
    # CORE METHOD
    # ------------------------------
    def perform_task(self, prompt: str, metadata: Dict[str, Any] = None) -> Dict[str, Any]:
        """
        Main entry for the UI Model agent.
        1. Load metadata from ArchitectMain phase
        2. Get existing files
        3. Ask LLM for UI components and models
        4. Create files and apply modifications
        5. Create common components
        6. Update metadata.json
        """
        
        self.log("Loading metadata from ArchitectMain phase...")
        self.load_metadata()
        
        self.log(f"Working on project: {self.app_name}")
        self.log(f"Project root: {self.project_root}")
        
        # Get existing files
        existing_files = self.get_existing_files()
        self.log(f"Found {len(existing_files)} existing Swift files")
        
        # Ask LLM for UI components
        self.log("Querying LLM for UI components and models...")
        llm_result = self.ask_llm_for_ui_components(prompt, existing_files)
        
        file_changes = {}
        
        # Create new files from LLM
        if "new_files" in llm_result and llm_result["new_files"]:
            self.log(f"Creating {len(llm_result['new_files'])} new files...")
            new_file_changes = self.create_new_files(llm_result["new_files"])
            file_changes.update(new_file_changes)
        
        # Modify existing files
        if "modifications" in llm_result and llm_result["modifications"]:
            self.log(f"Applying {len(llm_result['modifications'])} modifications...")
            mod_file_changes = self.modify_existing_files(llm_result["modifications"])
            file_changes.update(mod_file_changes)
        
        # Create color assets
        if "color_scheme_updates" in llm_result:
            self.log("Creating color assets...")
            color_changes = self.create_color_assets(llm_result["color_scheme_updates"])
            file_changes.update(color_changes)
        
        # Create common components
        self.log("Creating common UI components...")
        component_changes = self.create_common_components()
        file_changes.update(component_changes)
        
        # Update main files with imports
        self.log("Updating main files with imports...")
        import_changes = self.update_main_files_with_imports()
        file_changes.update(import_changes)
        
        # Update metadata
        updated_metadata = self.update_metadata(file_changes)
        
        return {
            "app_name": self.app_name,
            "llm_result": llm_result,
            "file_changes": file_changes,
            "metadata": updated_metadata
        }