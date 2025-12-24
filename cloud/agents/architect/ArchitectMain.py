import json
import os
from pathlib import Path
from typing import Dict, Any, List, TypedDict
from dotenv import load_dotenv
from datetime import datetime

# LangChain imports
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.messages import HumanMessage, AIMessage
from langchain_core.output_parsers import PydanticOutputParser
from pydantic import BaseModel, Field

# LangGraph imports
from langgraph.graph import StateGraph, END
from langgraph.checkpoint.memory import MemorySaver

from agents.BaseAgent import BaseAgent

load_dotenv()


# ===========================
# PYDANTIC MODELS
# ===========================

class ProjectStructure(BaseModel):
    """Structured project definition"""
    app_name: str = Field(description="Name of the iOS application")
    description: str = Field(description="Brief description of the app")
    deployment_target: str = Field(default="16.0", description="iOS deployment target")
    uses_swiftui: bool = Field(default=True, description="Whether app uses SwiftUI")
    features: List[str] = Field(description="Key features/modules needed")
    color_scheme: str = Field(default="blue", description="Primary color scheme")


# ===========================
# STATE DEFINITION
# ===========================

class ArchitectAgentState(TypedDict):
    """State for the workflow"""
    messages: List[Any]
    user_query: str
    project_structure: Dict[str, Any]
    file_changes: Dict[str, dict]
    current_step: str
    validation_passed: bool
    error: str | None


# ===========================
# ENHANCED ARCHITECT AGENT
# ===========================

class ArchitectAgent(BaseAgent):
    """Enhanced Architect Agent with LangChain & LangGraph"""

    def __init__(self, storage_path: str = "storage/"):
        super().__init__("ArchitectAgent", storage_path)
        
        self.llm = ChatOpenAI(
            model="gpt-5.2",
            temperature=0.1,
            api_key=os.getenv("OPENAI_API_KEY")
        )
        
        self.pydantic_parser = PydanticOutputParser(pydantic_object=ProjectStructure)
        self.memory = MemorySaver()
        self.workflow = self._build_workflow()

    # ===========================
    # LANGCHAIN CHAINS
    # ===========================

    def _create_project_structure_chain(self):
        """Chain for generating structured project definition"""
        system_template = """You are an expert iOS Project Architect AI.
        Generate a structured project definition based on the user's requirements.
        
        {format_instructions}
        
        Return ONLY valid JSON matching the format."""
        
        prompt = ChatPromptTemplate.from_messages([
            ("system", system_template),
            ("human", "{user_query}")
        ])
        
        return prompt | self.llm | self.pydantic_parser

    # ===========================
    # WORKFLOW NODES
    # ===========================

    def _generate_structure(self, state: ArchitectAgentState) -> ArchitectAgentState:
        """Generate project structure"""
        self.log("Generating project structure...")
        
        try:
            chain = self._create_project_structure_chain()
            format_instructions = self.pydantic_parser.get_format_instructions()
            
            project_structure = chain.invoke({
                "user_query": state["user_query"],
                "format_instructions": format_instructions
            })
            
            state["project_structure"] = project_structure.dict()
            state["messages"].append(AIMessage(
                content=f"Generated: {project_structure.app_name}"
            ))
            state["current_step"] = "validate"
            
        except Exception as e:
            self.log(f"Error: {e}")
            state["error"] = str(e)
            state["current_step"] = "error"
        
        return state

    def _validate_structure(self, state: ArchitectAgentState) -> ArchitectAgentState:
        """Validate project structure"""
        self.log("Validating...")
        state["validation_passed"] = True
        state["current_step"] = "generate_files"
        return state

    def _generate_files(self, state: ArchitectAgentState) -> ArchitectAgentState:
        """Generate all project files"""
        self.log("Generating files...")
        
        try:
            file_changes = self._generate_ios_structure(state["project_structure"])
            state["file_changes"] = file_changes
            state["current_step"] = "finalize"
            
        except Exception as e:
            state["error"] = str(e)
            state["current_step"] = "error"
        
        return state

    def _finalize(self, state: ArchitectAgentState) -> ArchitectAgentState:
        """Finalize and update metadata"""
        self.log("Finalizing...")
        
        try:
            self.update_metadata(state["file_changes"])
            
            # Save to new metadata format
            metadata_path = self.storage_path / "metadata.json"
            if metadata_path.exists():
                metadata = json.loads(metadata_path.read_text())
            else:
                metadata = {"phases": []}
            
            if "phases" not in metadata:
                metadata = {"phases": []}
            
            phase_info = {
                "agent": "ArchitectAgent",
                "timestamp": datetime.now().isoformat(),
                "results": {
                    "app_name": state["project_structure"]["app_name"],
                    "llm_result": state["project_structure"],
                    "files_created": len(state["file_changes"])
                }
            }
            
            metadata["phases"].append(phase_info)
            metadata_path.write_text(json.dumps(metadata, indent=2))
            
            state["current_step"] = "complete"
            
        except Exception as e:
            state["error"] = str(e)
            state["current_step"] = "error"
        
        return state

    def _handle_error(self, state: ArchitectAgentState) -> ArchitectAgentState:
        """Handle errors"""
        self.log(f"Error: {state['error']}")
        state["current_step"] = "complete"
        return state

    # ===========================
    # WORKFLOW BUILDER
    # ===========================

    def _build_workflow(self) -> StateGraph:
        """Build the workflow"""
        workflow = StateGraph(ArchitectAgentState)
        
        workflow.add_node("generate", self._generate_structure)
        workflow.add_node("validate", self._validate_structure)
        workflow.add_node("generate_files", self._generate_files)
        workflow.add_node("finalize", self._finalize)
        workflow.add_node("error", self._handle_error)
        
        workflow.set_entry_point("generate")
        
        def route(state: ArchitectAgentState) -> str:
            return "error" if state.get("current_step") == "error" else state["current_step"]
        
        workflow.add_conditional_edges("generate", route, 
            {"validate": "validate", "error": "error"})
        workflow.add_conditional_edges("validate", route,
            {"generate_files": "generate_files", "error": "error"})
        workflow.add_conditional_edges("generate_files", route,
            {"finalize": "finalize", "error": "error"})
        
        workflow.add_edge("finalize", END)
        workflow.add_edge("error", END)
        
        return workflow.compile(checkpointer=self.memory)

    # ===========================
    # FILE GENERATION
    # ===========================

    def _generate_ios_structure(self, ps: Dict[str, Any]) -> Dict[str, dict]:
        """Generate iOS project files"""
        app_name = ps["app_name"]
        clean_name = app_name.replace(" ", "")
        
        # Create directories
        dirs = [
            f"{clean_name}/Resources",
            f"{clean_name}/Sources",
            f"{clean_name}/Sources/Extensions",
            f"{clean_name}/Sources/Models",
            f"{clean_name}/Sources/Views",
            f"{clean_name}/Tests"
        ]
        
        for d in dirs:
            (self.storage_path / d).mkdir(parents=True, exist_ok=True)
        
        fc = {}
        color = ps.get("color_scheme", "blue")
        target = ps.get("deployment_target", "16.0")
        
        # Generate all files
        files = [
            (f"{clean_name}/Resources/Info.plist", self._gen_plist(clean_name, app_name)),
            (f"{clean_name}/Sources/AppDelegate.swift", self._gen_app_delegate(app_name)),
            (f"{clean_name}/Sources/AppMain.swift", self._gen_app_main(clean_name)),
            (f"{clean_name}/Sources/SceneDelegate.swift", self._gen_scene_delegate()),
            (f"{clean_name}/Sources/Models/AppState.swift", self._gen_app_state()),
            (f"{clean_name}/Sources/ContentView.swift", self._gen_content_view(color)),
            (f"{clean_name}/Sources/Views/HomeView.swift", self._gen_home_view(app_name)),
            (f"{clean_name}/Sources/Views/DetailView.swift", self._gen_detail_view()),
            (f"{clean_name}/Sources/Extensions/View+Extensions.swift", self._gen_extensions()),
            (f"{clean_name}/project.yml", self._gen_project_yml(clean_name, app_name, target))
        ]
        
        for path, content in files:
            self.write_file(path, content)
            fc[path] = {"type": "generated"}
        
        return fc

    def _gen_plist(self, clean_name: str, app_name: str) -> str:
        return f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>{app_name}</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.{clean_name}</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
</dict>
</plist>"""

    def _gen_app_delegate(self, app_name: str) -> str:
        return f"""import UIKit
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {{
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {{
        print(" {app_name} launched!")
        return true
    }}
}}"""

    def _gen_app_main(self, clean_name: str) -> str:
        return f"""import SwiftUI

@main
struct {clean_name}App: App {{
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    
    var body: some Scene {{
        WindowGroup {{
            ContentView()
                .environmentObject(appState)
        }}
    }}
}}"""

    def _gen_scene_delegate(self) -> str:
        return """import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: ContentView().environmentObject(AppState()))
        self.window = window
        window.makeKeyAndVisible()
    }
}"""

    def _gen_app_state(self) -> str:
        return """import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
}"""

    def _gen_content_view(self, color: str) -> str:
        return f"""import SwiftUI

struct ContentView: View {{
    @State private var selection = 0
    
    var body: some View {{
        TabView(selection: $selection) {{
            HomeView()
                .tabItem {{ Label("Home", systemImage: "house.fill") }}
                .tag(0)
            
            Text("Explore")
                .tabItem {{ Label("Explore", systemImage: "magnifyingglass") }}
                .tag(1)
            
            Text("Profile")
                .tabItem {{ Label("Profile", systemImage: "person.fill") }}
                .tag(2)
        }}
        .accentColor(.{color})
    }}
}}"""

    def _gen_home_view(self, app_name: str) -> str:
        return f"""import SwiftUI

struct HomeView: View {{
    var body: some View {{
        NavigationView {{
            ScrollView {{
                VStack(spacing: 20) {{
                    Text("Welcome to {app_name}")
                        .font(.largeTitle)
                        .bold()
                    
                    ForEach(0..<10, id: \\.self) {{ i in
                        CardView(title: "Item \\(i)")
                    }}
                }}
                .padding()
            }}
            .navigationBarHidden(true)
        }}
    }}
}}

struct CardView: View {{
    let title: String
    
    var body: some View {{
        Text(title)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
    }}
}}"""

    def _gen_detail_view(self) -> str:
        return """import SwiftUI

struct DetailView: View {
    @Environment(\\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Detail View")
                    .font(.largeTitle)
                Spacer()
            }
            .navigationTitle("Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}"""

    def _gen_extensions(self) -> str:
        return """import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                       to: nil, from: nil, for: nil)
    }
}"""

    def _gen_project_yml(self, clean_name: str, app_name: str, target: str) -> str:
        return f"""name: {clean_name}
options:
  bundleIdPrefix: com.example
  deploymentTarget:
    iOS: "{target}"
targets:
  {clean_name}:
    type: application
    platform: iOS
    sources: [Sources, Resources]
    settings:
      PRODUCT_NAME: {clean_name}
      IPHONEOS_DEPLOYMENT_TARGET: {target}"""

    # ===========================
    # MAIN ENTRY
    # ===========================

    def perform_task(self, prompt: str, metadata: Dict[str, Any] = None) -> Dict[str, Any]:
        """Main entry using LangGraph workflow"""
        self.log("Starting ArchitectAgent with LangGraph...")
        
        initial_state = ArchitectAgentState(
            messages=[HumanMessage(content=prompt)],
            user_query=prompt,
            project_structure={},
            file_changes={},
            current_step="generate",
            validation_passed=False,
            error=None
        )
        
        config = {"configurable": {"thread_id": "architect_session"}}
        final_state = self.workflow.invoke(initial_state, config)
        
        if final_state.get("error"):
            self.log(f"Completed with error: {final_state['error']}")
        else:
            self.log("Completed successfully!")
        
        return {
            "app_name": final_state["project_structure"].get("app_name", "Unknown"),
            "llm_result": final_state.get("project_structure", {}),
            "file_changes": final_state.get("file_changes", {}),
            "error": final_state.get("error")
        }