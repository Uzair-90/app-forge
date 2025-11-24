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


import os
import json
from pathlib import Path

class BaseAgent:
    def __init__(self, name, storage_path):
        self.name = name
        self.storage_path = Path(storage_path)
        self.metadata_file = self.storage_path / "metadata.json"
        self.storage_path.mkdir(parents=True, exist_ok=True)
        if not self.metadata_file.exists():
            self.metadata_file.write_text(json.dumps({}, indent=2))

    def log(self, message):
        print(f"[{self.name}] {message}")

    async def perform_task(self, prompt, metadata):
        raise NotImplementedError("perform_task must be implemented by subclass")

    def update_metadata(self, file_changes):
        metadata = json.loads(self.metadata_file.read_text())
        for file, info in file_changes.items():
            metadata[file] = {"agent": self.name, **info}
        self.metadata_file.write_text(json.dumps(metadata, indent=2))
        self.log("Metadata updated")
        return metadata

