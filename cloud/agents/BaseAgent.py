"""
BaseAgent class - Core template for all agents in APP-FORGE cloud system.

Purpose:
    - Provides a consistent interface for all agents (Architect, UI, Logic, Docs, Validator).
    - Handles basic functionality shared by all agents, such as:
        * Logging
        * Metadata management (.json tracking of generated/modified files)
        * Storage path setup
        * Enforcing implementation of perform_task()

Key Methods:
    - perform_task(prompt, metadata):
        Abstract method that each subclass must implement.
        Accepts the user prompt and current metadata, returns file changes.
    - update_metadata(file_changes):
        Updates metadata.json with files generated or modified by the agent.
    - log(message):
        Logs messages prefixed with the agent's name for clarity.

Usage:
    - All agents inherit from BaseAgent and implement their own perform_task logic.
    - Orchestrator calls each agent sequentially or asynchronously.
    - Metadata ensures proper tracking of which agent owns which files.
"""

import json
from pathlib import Path
from typing import Dict, Any

class BaseAgent:
    def __init__(self, name: str, storage_path: str):
        self.name = name
        self.storage_path = Path(storage_path).resolve()  # resolve absolute path
        self.storage_path.mkdir(parents=True, exist_ok=True)

        self.metadata_file = self.storage_path / "metadata.json"
        if not self.metadata_file.exists():
            self.metadata_file.write_text(json.dumps({}, indent=2))

    def log(self, message: str):
        print(f"[{self.name}] {message}")

    def write_file(self, relative_path: str, content: str):
        target = self.storage_path / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content)
        self.log(f"Wrote file: {relative_path}")

    def update_metadata(self, file_changes: Dict[str, dict]) -> dict:
        metadata = json.loads(self.metadata_file.read_text())
        for file, info in file_changes.items():
            metadata[file] = {"agent": self.name, **info}
        self.metadata_file.write_text(json.dumps(metadata, indent=2))
        self.log("Metadata updated")
        return metadata
