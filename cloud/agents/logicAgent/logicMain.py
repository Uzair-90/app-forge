import json
import os
from pathlib import Path
from typing import Dict, Any, List
from dotenv import load_dotenv

# LangChain imports
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, AIMessage, SystemMessage

# LangGraph imports
from langgraph.graph import StateGraph, END

# Base imports
from agents.BaseAgent import BaseAgent

load_dotenv()


class LogicAgent(BaseAgent):
    """
    Logic Agent for iOS projects using LangGraph:
        - Takes user request and metadata.json from ArchitectMain phase
        - Creates business logic, services, managers, and utilities
        - Updates existing files with necessary logic implementations
        - Uses LangGraph for workflow orchestration
    """

    def __init__(self, storage_path: str = "storage/"):
        super().__init__("LogicAgent", storage_path)
        self.llm = ChatOpenAI(model="gpt-5.2", temperature=0.1)
        self.metadata = None
        self.project_root = None
        self.app_name = None
        self.clean_name = None
        self.workflow = self._build_workflow()

    # ------------------------------
    # METADATA & PROJECT SETUP
    # ------------------------------
    def load_metadata(self) -> Dict[str, Any]:
        """Load metadata.json from storage."""
        metadata_path = self.storage_path / "metadata.json"
        if not metadata_path.exists():
            raise FileNotFoundError(f"metadata.json not found at {metadata_path}")
        
        metadata = json.loads(metadata_path.read_text())
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
    def ask_llm_for_logic_components(self, query: str, existing_files: List[str]) -> Dict[str, Any]:
        """Calls the LLM to design logic components and services."""

        system_prompt = """
        You are an expert iOS software architect specializing in backend logic and business rules.
        Your job is to create data models, services, managers, view models, and utilities based on user requirements.

        The user will provide:
        1. Their requirements for business logic/services
        2. List of existing Swift files in the project (to avoid duplication)

        You MUST return ONLY valid JSON with the following structure:
        {
            "new_files": [
                {
                    "path": "relative/path/to/file.swift",
                    "type": "model|service|viewmodel|manager|utility",
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
        1. Paths should be relative to the project root (e.g., "Sources/Services/AuthService.swift")
        2. Never duplicate existing files
        3. Follow Swift best practices and naming conventions
        4. Use modern Swift (async/await, Codable, Combine)
        5. Implement proper error handling
        6. Ensure dependency injection
        7. Add comprehensive documentation
        8. Use SOLID principles
        """

        existing_files_str = "\n".join(existing_files)
        user_prompt = f"Requirements: {query}\n\nExisting files:\n{existing_files_str}"

        response = self.llm.invoke([
            SystemMessage(content=system_prompt),
            HumanMessage(content=user_prompt)
        ])

        content = response.content.strip()
        if content.startswith("```"):
            content = content.strip("```").replace("json", "").strip()
        
        return json.loads(content)

    def ask_llm_for_content_update(self, file_path: str, current_content: str, requirements: str) -> str:
        """Ask LLM to update existing file content."""
        
        system_prompt = """
        You are an expert Swift developer. Update the given Swift file based on the requirements.
        Return ONLY the complete updated Swift code, no explanations.
        Maintain the existing structure and style.
        Add proper imports if needed.
        """
        
        user_prompt = f"File: {file_path}\n\nCurrent content:\n{current_content}\n\nRequirements: {requirements}"
        
        response = self.llm.invoke([
            SystemMessage(content=system_prompt),
            HumanMessage(content=user_prompt)
        ])
        
        return response.content

    # ------------------------------
    # LANGGRAPH NODES
    # ------------------------------
    def analyze_requirements(self, state: dict) -> dict:
        """Node: Analyze user requirements"""
        self.log("Analyzing requirements...")
        
        existing_files = state["existing_files"]
        user_query = state["user_query"]
        
        system_prompt = """
        Analyze the logic requirements for this iOS project.
        Determine what data models, services, and utilities are needed.
        Return a brief analysis summary.
        """
        
        existing_files_str = "\n".join(existing_files)
        user_prompt = f"Requirements: {user_query}\n\nExisting files:\n{existing_files_str}"
        
        response = self.llm.invoke([
            SystemMessage(content=system_prompt),
            HumanMessage(content=user_prompt)
        ])
        
        state["analysis"] = response.content
        state["current_step"] = "generate_components"
        return state

    def generate_components(self, state: dict) -> dict:
        """Node: Generate logic components using LLM"""
        self.log("Generating logic components...")
        
        llm_result = self.ask_llm_for_logic_components(
            state["user_query"], 
            state["existing_files"]
        )
        
        state["llm_result"] = llm_result
        state["current_step"] = "create_files"
        return state

    def create_files(self, state: dict) -> dict:
        """Node: Create new files"""
        self.log("Creating new files...")
        
        file_changes = {}
        new_files = state["llm_result"].get("new_files", [])
        
        for file_info in new_files:
            project_relative_path = file_info["path"]
            storage_relative_path = f"{self.clean_name}/{project_relative_path}"
            content = file_info["content"]
            file_type = file_info.get("type", "service")
            
            full_path = self.storage_path / storage_relative_path
            full_path.parent.mkdir(parents=True, exist_ok=True)
            
            self.write_file(storage_relative_path, content)
            file_changes[storage_relative_path] = {
                "type": "created",
                "file_type": file_type
            }
        
        state["file_changes"] = file_changes
        state["current_step"] = "modify_files"
        return state

    def modify_files(self, state: dict) -> dict:
        """Node: Modify existing files"""
        self.log("Modifying existing files...")
        
        modifications = state["llm_result"].get("modifications", [])
        
        for mod_info in modifications:
            project_relative_path = mod_info["file"]
            storage_relative_path = f"{self.clean_name}/{project_relative_path}"
            full_path = self.storage_path / storage_relative_path
            
            if not full_path.exists():
                self.log(f"Warning: {storage_relative_path} doesn't exist, skipping")
                continue
            
            current_content = full_path.read_text()
            requirements = f"Apply these changes: {json.dumps(mod_info['changes'])}"
            
            updated_content = self.ask_llm_for_content_update(
                project_relative_path, 
                current_content, 
                requirements
            )
            
            self.write_file(storage_relative_path, updated_content)
            state["file_changes"][storage_relative_path] = {
                "type": "modified",
                "changes": len(mod_info["changes"])
            }
        
        state["current_step"] = "finalize"
        return state

    def finalize(self, state: dict) -> dict:
        """Node: Finalize and update metadata"""
        self.log("Finalizing...")
        
        updated_metadata = self.update_metadata(state["file_changes"])
        state["metadata"] = updated_metadata
        return state

    # ------------------------------
    # LANGGRAPH WORKFLOW BUILDER
    # ------------------------------
    def _build_workflow(self) -> StateGraph:
        """Build the LangGraph workflow"""
        workflow = StateGraph(dict)
        
        # Add nodes
        workflow.add_node("analyze", self.analyze_requirements)
        workflow.add_node("generate", self.generate_components)
        workflow.add_node("create_files", self.create_files)
        workflow.add_node("modify_files", self.modify_files)
        workflow.add_node("finalize", self.finalize)
        
        # Set edges
        workflow.set_entry_point("analyze")
        workflow.add_edge("analyze", "generate")
        workflow.add_edge("generate", "create_files")
        workflow.add_edge("create_files", "modify_files")
        workflow.add_edge("modify_files", "finalize")
        workflow.add_edge("finalize", END)
        
        return workflow.compile()

    # ------------------------------
    # CORE METHOD
    # ------------------------------
    def perform_task(self, prompt: str, metadata: Dict[str, Any] = None) -> Dict[str, Any]:
        """
        Main entry for the Logic agent using LangGraph.
        """
        self.log("Starting Logic Agent with LangGraph...")
        
        # Load metadata
        self.load_metadata()
        self.log(f"Working on project: {self.app_name}")
        
        # Get existing files
        existing_files = self.get_existing_files()
        self.log(f"Found {len(existing_files)} existing Swift files")
        
        # Initial state
        initial_state = {
            "user_query": prompt,
            "existing_files": existing_files,
            "llm_result": {},
            "file_changes": {},
            "current_step": "analyze",
            "app_name": self.app_name
        }
        
        # Run workflow
        final_state = self.workflow.invoke(initial_state)
        
        return {
            "app_name": self.app_name,
            "llm_result": final_state.get("llm_result", {}),
            "file_changes": final_state.get("file_changes", {}),
            "metadata": final_state.get("metadata", {}),
            "analysis": final_state.get("analysis", "")
        }