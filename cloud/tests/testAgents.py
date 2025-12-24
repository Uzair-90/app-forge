# testBothAgents.py
import json
import time
from pathlib import Path
from agents.architect.ArchitectMain import ArchitectAgent
from agents.uiAgent.UIAgent import UIModelAgent
from agents.logicAgent.logicMain import LogicAgent

def get_app_context_from_metadata():
    """Extract app context from metadata to pass between agents."""
    metadata_path = Path("storage/metadata.json")
    if not metadata_path.exists():
        return {"description": "An iOS application", "app_name": "MyApp"}
    
    with open(metadata_path, "r") as f:
        metadata = json.load(f)
    
    context = {"description": "An iOS application", "app_name": "MyApp", "existing_files": []}
    
    if "phases" in metadata:
        # New format: Find ArchitectAgent phase
        for phase in reversed(metadata.get("phases", [])):
            if phase.get("agent") == "ArchitectAgent":
                results = phase.get("results", {})
                context["app_name"] = results.get("app_name", "MyApp")
                context["description"] = results.get("llm_result", {}).get("description", "An iOS application")
                context["features"] = results.get("llm_result", {}).get("features", [])
                break
    else:
        # Old format: Extract from file paths
        if metadata:
            last_key = list(metadata.keys())[-1]
            context["app_name"] = last_key.split('/')[0]
    
    return context

def main():
    print("=" * 60)
    print("iOS APP GENERATION PIPELINE")
    print("=" * 60)
    
    # ----------------------------
    # USER REQUEST
    # ----------------------------
    print("\n📱 STEP 1: App Requirements")
    print("-" * 40)
    
    # You can hardcode or take user input
    user_request = "Build me to-do list Applicatioin for iOS"
    # For interactive mode, uncomment:
    # user_request = input("Describe your iOS app: ").strip()
    # if not user_request:
    #     user_request = "Build me a Notes Taking App for iOS"
    
    print(f"App request: {user_request}")
    
    # ----------------------------
    # 1. ARCHITECT AGENT PHASE
    # ----------------------------
    print("\n🧱 STEP 2: Project Architecture")
    print("-" * 40)
    print("Creating project structure...")
    
    try:
        architect = ArchitectAgent()
        arch_result = architect.perform_task(user_request)
        
        print(f"✓ Project created: {arch_result['app_name']}")
        print(f"✓ Generated {len(arch_result['file_changes'])} base files")
        
        # Store architect results for context
        app_name = arch_result["app_name"]
        clean_name = app_name.replace(" ", "")
        
        # Brief wait for file operations
        time.sleep(0.3)
        
    except Exception as e:
        print(f"✗ ArchitectAgent failed: {e}")
        return
    
    # ----------------------------
    # 2. UI AGENT PHASE
    # ----------------------------
    print("\n🎨 STEP 3: UI Components")
    print("-" * 40)
    print("Creating UI components...")
    
    try:
        ui_agent = UIModelAgent()
        
        # Dynamic UI prompt based on app context
        ui_prompt = f"""
        Based on this app description:
        "{user_request}"
        
        Create all necessary UI components, views, and interface elements.
        Design appropriate screens, navigation, and user interactions.
        Include proper SwiftUI components, styling, and previews.
        """
        
        ui_result = ui_agent.perform_task(ui_prompt)
        
        print(f"✓ UI components created: {len(ui_result['file_changes'])}")
        
    except Exception as e:
        print(f"✗ UIModelAgent failed: {e}")
        ui_result = {"file_changes": {}}
        # Continue pipeline despite UI errors
    
    # ----------------------------
    # 3. LOGIC AGENT PHASE
    # ----------------------------
    print("\n🧠 STEP 4: Backend Logic")
    print("-" * 40)
    print("Creating data models and business logic...")
    
    try:
        logic_agent = LogicAgent()
        
        # Get app context from metadata
        app_context = get_app_context_from_metadata()
        
        # Dynamic logic prompt based on actual app
        logic_prompt = f"""
        App Description: {app_context.get('description', user_request)}
        App Name: {app_context.get('app_name', app_name)}
        
        Create all necessary backend logic, data models, services, and business logic.
        
        Requirements:
        1. Design appropriate data models based on the app type
        2. Create service layers for data operations (CRUD)
        3. Implement view models for UI binding
        4. Add validation and error handling
        5. Choose appropriate persistence strategy
        6. Include proper architecture patterns (MVVM, Clean Architecture)
        7. Add comprehensive documentation
        8. Create test stubs for critical functions
        
        Important: Analyze the existing project structure and create logic that
        complements what's already been built by previous agents.
        """
        
        logic_result = logic_agent.perform_task(logic_prompt)
        
        print(f"✓ Logic components created: {len(logic_result.get('file_changes', {}))}")
        
        # Show architecture insights
        if 'architecture_summary' in logic_result:
            summary = logic_result['architecture_summary']
            if summary.get('core_entities'):
                print(f"📊 Core entities: {', '.join(summary['core_entities'])}")
        
    except Exception as e:
        print(f"✗ LogicAgent failed: {e}")
        logic_result = {"file_changes": {}}
    
    # ----------------------------
    # FINAL SUMMARY
    # ----------------------------
    print("\n" + "=" * 60)
    print("✅ PIPELINE COMPLETE")
    print("=" * 60)
    
    total_files = (
        len(arch_result["file_changes"]) + 
        len(ui_result.get("file_changes", {})) + 
        len(logic_result.get("file_changes", {}))
    )
    
    print(f"Project: {app_name}")
    print(f"Location: storage/{clean_name}/")
    print(f"Total files generated: {total_files}")
    
    # List file categories
    print("\nFile breakdown:")
    print(f"  • Architecture: {len(arch_result['file_changes'])} files")
    print(f"  • UI Components: {len(ui_result.get('file_changes', {}))} files")
    print(f"  • Backend Logic: {len(logic_result.get('file_changes', {}))} files")
    
    # Show project structure
    project_dir = Path("storage") / clean_name
    if project_dir.exists():
        print(f"\nProject structure created in: storage/{clean_name}/")
        print("Key directories:")
        for dir_path in sorted(project_dir.glob("*/")):
            if dir_path.is_dir():
                rel_path = dir_path.relative_to(project_dir)
                print(f"  📁 {rel_path}/")
    
    print("\nTo build:")
    print(f"  cd storage/{clean_name}")
    print("  xcodegen generate")
    print("  open *.xcodeproj")
    print("=" * 60)
    
    return {
        "architect": arch_result,
        "ui_agent": ui_result,
        "logic_agent": logic_result
    }

if __name__ == "__main__":
    results = main()