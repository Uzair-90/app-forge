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
        
        # Look for ArchitectAgent phase
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
        
        self.clean_name = self.app_name.replace(" ", "")
        self.project_root = self.storage_path / self.clean_name
        
        return metadata

    def get_existing_files(self) -> List[str]:
        """Get list of existing Swift files in the project."""
        swift_files = []
        if not self.project_root or not self.project_root.exists():
            return swift_files
            
        for root, dirs, files in os.walk(self.project_root):
            for file in files:
                if file.endswith(".swift"):
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
            ]
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
            model="gpt-5.2",
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
            model="gpt-5.2",
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
            project_relative_path = file_info["path"]
            content = file_info["content"]
            file_type = file_info.get("type", "view")
            
            storage_relative_path = f"{self.clean_name}/{project_relative_path}"
            full_path = self.storage_path / storage_relative_path
            
            full_path.parent.mkdir(parents=True, exist_ok=True)
            
            self.write_file(storage_relative_path, content)
            file_changes[storage_relative_path] = {"type": "created", "file_type": file_type}
            
            self.log(f"Created {file_type}: {storage_relative_path}")
        
        return file_changes

    def modify_existing_files(self, modifications: List[Dict[str, Any]]) -> Dict[str, dict]:
        """Modify existing Swift files."""
        file_changes = {}
        
        for mod_info in modifications:
            project_relative_path = mod_info["file"]
            
            storage_relative_path = f"{self.clean_name}/{project_relative_path}"
            full_path = self.storage_path / storage_relative_path
            
            if not full_path.exists():
                self.log(f"Warning: File {storage_relative_path} doesn't exist, skipping modifications")
                continue
            
            with open(full_path, "r") as f:
                current_content = f.read()
            
            requirements = f"Apply these changes: {json.dumps(mod_info['changes'])}"
            updated_content = self.ask_llm_for_content_update(project_relative_path, current_content, requirements)
            
            self.write_file(storage_relative_path, updated_content)
            file_changes[storage_relative_path] = {"type": "modified", "changes": len(mod_info["changes"])}
            
            self.log(f"Modified: {storage_relative_path}")
        
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
        5. Update metadata.json
        """
        
        self.log("Loading metadata from ArchitectMain phase...")
        self.load_metadata()
        
        self.log(f"Working on project: {self.app_name}")
        self.log(f"Project root: {self.project_root}")
        
        existing_files = self.get_existing_files()
        self.log(f"Found {len(existing_files)} existing Swift files")
        
        self.log("Querying LLM for UI components and models...")
        llm_result = self.ask_llm_for_ui_components(prompt, existing_files)
        
        file_changes = {}
        
        if "new_files" in llm_result and llm_result["new_files"]:
            self.log(f"Creating {len(llm_result['new_files'])} new files...")
            new_file_changes = self.create_new_files(llm_result["new_files"])
            file_changes.update(new_file_changes)
        
        if "modifications" in llm_result and llm_result["modifications"]:
            self.log(f"Applying {len(llm_result['modifications'])} modifications...")
            mod_file_changes = self.modify_existing_files(llm_result["modifications"])
            file_changes.update(mod_file_changes)
        
        updated_metadata = self.update_metadata(file_changes)
        
        return {
            "app_name": self.app_name,
            "llm_result": llm_result,
            "file_changes": file_changes,
            "metadata": updated_metadata
        }