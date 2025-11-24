"""
	- Creating a basic project skeleton (folder + initial files)'
	- Logging its actions
	- Updating metadata.json with files it created
	- Returning the list of file changes for furthure processing by other agents
"""

from agents.BaseAgent import BaseAgent
from pathlib import Path

class ArchitectAgent(BaseAgent):
    async def perform_task(self, prompt, metadata):
        self.log(f"Generating project skeleton for prompt: {prompt}")
        project_path = Path(self.storage_path) / "project"
        folders = ["Models", "Views", "Controllers"]
        project_path.mkdir(exist_ok=True)
        for f in folders:
            (project_path / f).mkdir(exist_ok=True)
        file_changes = {
            "project/README.md": {"type": "doc", "description": "Initial README generated"}
        }
        self.update_metadata(file_changes)
        return file_changes

