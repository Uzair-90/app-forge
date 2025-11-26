import os
import json
import asyncio
import re
from pathlib import Path
from typing import Dict, Any
from dotenv import load_dotenv
from openai import OpenAI  # Updated import for new OpenAI API

from agents.BaseAgent import BaseAgent

# Load .env from cloud/.env
env_path = Path(__file__).resolve().parents[2] / ".env"
if env_path.exists():
    load_dotenv(env_path)

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4")

# Initialize OpenAI client
client = None
if OPENAI_API_KEY:
    client = OpenAI(api_key=OPENAI_API_KEY)


class ArchitectAgent(BaseAgent):

    async def perform_task(self, prompt: str, metadata: Dict[str, Any]):
        """
        1) Ask OpenAI for JSON describing project name, folders & files.
        2) Parse JSON.
        3) Create project folder under storage using project_name.
        4) Write folders/files.
        5) Update metadata.json.
        """

        self.log(f"[Architect] Prompt: {prompt}")

        # ----------------------------------------------
        # Enhanced system prompt for better project structure
        # ----------------------------------------------
        system_msg = """
You are an expert software architect. Analyze the project requirements and create an optimal project structure.

CRITICAL: Return ONLY valid JSON, no other text.

Output Format:
{
  "project_name": "meaningful-kebab-case-name",
  "description": "brief project description",
  "architecture": {
    "type": "ios-app|web-app|backend-api|desktop-app|library",
    "framework": "swiftui|react|django|flutter|etc",
    "patterns": ["mvvm", "mvc", "clean-architecture", "etc"]
  },
  "folders": ["Sources", "Tests", "Resources", "Documentation", "Configuration"],
  "files": {
    "path/to/file.ext": "file content...",
    "README.md": "# Project Overview\\n\\nDescription...",
    "Package.swift": "// Swift package manifest",
    "project.json": "// Project configuration"
  }
}

GUIDELINES:
1. Project Name: Create short, memorable, kebab-case names that reflect the project's purpose
2. Architecture: Choose appropriate architecture based on project type (iOS, web, backend, etc.)
3. Folders: Use standard directory structures for the project type
4. Files: Include essential starter files (README, configuration, core source files)
5. Content: Provide meaningful starter code/content appropriate for the file type

EXAMPLES:

Input: "Create a weather app for iOS"
Output:
{
  "project_name": "weather-forecast",
  "description": "iOS weather application with location-based forecasts",
  "architecture": {
    "type": "ios-app",
    "framework": "swiftui",
    "patterns": ["mvvm", "combine"]
  },
  "folders": ["Sources", "Tests", "Resources", "Preview Content"],
  "files": {
    "README.md": "# Weather Forecast\\n\\nA modern iOS weather app built with SwiftUI.",
    "Package.swift": "// swift-tools-version: 5.7\\nimport PackageDescription\\n\\nlet package = Package(\\n    name: \\"WeatherForecast\\",\\n    platforms: [.iOS(.v16)],\\n    products: [.app(name: \\"WeatherForecast\\", targets: [\\"WeatherForecast\\"])],\\n    targets: [.target(name: \\"WeatherForecast\\")]\\n)",
    "Sources/Models/WeatherModel.swift": "import Foundation\\n\\nstruct WeatherData: Codable {\\n    let temperature: Double\\n    let condition: String\\n}\\n",
    "Sources/Views/WeatherView.swift": "import SwiftUI\\n\\nstruct WeatherView: View {\\n    var body: some View {\\n        Text(\\"Weather App\\")\\n    }\\n}\\n",
    "Tests/WeatherTests.swift": "import XCTest\\n@testable import WeatherForecast\\n\\nfinal class WeatherTests: XCTestCase {\\n    func testExample() {\\n        // Test code\\n    }\\n}"
  }
}

Input: "Build a REST API for task management"
Output:
{
  "project_name": "task-manager-api",
  "description": "RESTful API for task management with CRUD operations",
  "architecture": {
    "type": "backend-api",
    "framework": "nodejs-express",
    "patterns": ["rest", "mvc"]
  },
  "folders": ["src", "tests", "config", "docs"],
  "files": {
    "README.md": "# Task Manager API\\n\\nREST API for managing tasks.",
    "package.json": "{\\n  \\\"name\\\": \\\"task-manager-api\\\",\\n  \\\"version\\\": \\\"1.0.0\\\",\\n  \\\"scripts\\\": {\\n    \\\"start\\\": \\\"node src/server.js\\\"\\n  }\\n}",
    "src/server.js": "const express = require('express');\\nconst app = express();\\n\\napp.use(express.json());\\n\\napp.get('/tasks', (req, res) => {\\n  res.json({ tasks: [] });\\n});\\n\\napp.listen(3000, () => {\\n  console.log('Server running on port 3000');\\n});",
    "src/controllers/taskController.js": "class TaskController {\\n  static async getTasks(req, res) {\\n    // Implementation\\n  }\\n}\\n\\nmodule.exports = TaskController;"
  }
}
"""

        user_msg = f"Project requirements: {prompt}\n\nReturn valid JSON only."

        try:
            if not client:
                raise RuntimeError("OpenAI client not initialized - check OPENAI_API_KEY in cloud/.env")

            def call_openai():
                response = client.chat.completions.create(
                    model=OPENAI_MODEL,
                    messages=[
                        {"role": "system", "content": system_msg},
                        {"role": "user", "content": user_msg}
                    ],
                    temperature=0.1,
                    max_tokens=4000
                )
                return response.choices[0].message.content

            content = await asyncio.to_thread(call_openai)
            self.log(f"[Architect] OpenAI response received: {len(content)} characters")

        except Exception as e:
            self.log(f"[Architect] OpenAI request failed: {e}")
            # Return fallback as JSON string, not dict
            fallback_data = self._create_fallback_structure(prompt)
            content = json.dumps(fallback_data)

        # ----------------------------------------------
        # Parse JSON safely with multiple fallbacks
        # ----------------------------------------------
        data = self._parse_json_response(content, prompt)
        
        # ----------------------------------------------
        # Validate and enhance project structure
        # ----------------------------------------------
        project_name = self._validate_project_name(data.get("project_name"), prompt)
        description = data.get("description", f"Project for: {prompt}")
        architecture = data.get("architecture", {})
        
        self.log(f"[Architect] Project: {project_name}")
        self.log(f"[Architect] Description: {description}")
        self.log(f"[Architect] Architecture: {architecture}")

        project_root = Path(self.storage_path) / project_name
        project_root.mkdir(parents=True, exist_ok=True)
        
        # Write project metadata
        self._write_project_metadata(project_root, {
            "name": project_name,
            "description": description,
            "architecture": architecture,
            "prompt": prompt,
            "created_by": "ArchitectAgent"
        })

        folders = data.get("folders", [])
        files = data.get("files", {})
        created_files_info = {}

        # ----------------------------------------------
        # Create folder structure
        # ----------------------------------------------
        for folder in folders:
            folder_path = project_root / folder
            folder_path.mkdir(parents=True, exist_ok=True)
            self.log(f"[Architect] Created folder: {folder_path}")

        # ----------------------------------------------
        # Write files with enhanced logging
        # ----------------------------------------------
        for rel_path, contents in files.items():
            try:
                # Normalize path and remove any leading project names
                rel_path = Path(rel_path)
                parts = list(rel_path.parts)
                if parts and parts[0].lower() in ["project", project_name.lower().replace("-", "")]:
                    parts = parts[1:]
                
                if parts:  # Ensure we have valid path components
                    target_path = project_root / Path(*parts)
                    target_path.parent.mkdir(parents=True, exist_ok=True)
                    
                    # Ensure content is string and handle newlines properly
                    if isinstance(contents, str):
                        # Fix escaped newlines if present
                        content_str = contents.replace('\\n', '\n')
                    else:
                        content_str = str(contents)
                    
                    target_path.write_text(content_str, encoding='utf-8')
                    self.log(f"[Architect] Wrote file: {target_path} ({len(content_str)} chars)")
                    
                    created_files_info[str(target_path.relative_to(self.storage_path))] = {
                        "type": "file",
                        "description": f"Generated by ArchitectAgent for {project_name}",
                        "size": len(content_str)
                    }
            except Exception as e:
                self.log(f"[Architect] Error writing file {rel_path}: {e}")

        # ----------------------------------------------
        # Update metadata and return results
        # ----------------------------------------------
        self.update_metadata(created_files_info)

        return {
            "project_name": project_name,
            "project_root": str(project_root),
            "description": description,
            "architecture": architecture,
            "files_created": created_files_info
        }

    def _parse_json_response(self, content: str, prompt: str) -> Dict[str, Any]:
        """Parse JSON response with multiple fallback strategies."""
        # If content is already a dict (from fallback), return it
        if isinstance(content, dict):
            return content
            
        try:
            return json.loads(content)
        except json.JSONDecodeError:
            self.log("[Architect] Initial JSON parse failed, attempting extraction...")
            
        # Try to extract JSON from markdown code blocks or other wrappers
        json_patterns = [
            r'```json\s*(.*?)\s*```',  # JSON code blocks
            r'```\s*(.*?)\s*```',      # Any code blocks
            r'(\{.*\})',                # Anything that looks like JSON object
        ]
        
        for pattern in json_patterns:
            matches = re.findall(pattern, content, re.DOTALL)
            for match in matches:
                try:
                    if isinstance(match, tuple):
                        match = match[0]
                    return json.loads(match.strip())
                except json.JSONDecodeError:
                    continue
        
        # Final fallback
        self.log("[Architect] JSON extraction failed, using fallback structure")
        return self._create_fallback_structure(prompt)

    def _validate_project_name(self, project_name: str, prompt: str) -> str:
        """Create a meaningful project name from prompt if needed."""
        if project_name and self._is_valid_project_name(project_name):
            return project_name
        
        # Generate intelligent project name from prompt
        words = re.findall(r'\b[a-zA-Z]+(?:\s+[a-zA-Z]+)*\b', prompt.lower())
        meaningful_words = []
        
        # Filter out common stop words and focus on meaningful terms
        stop_words = {'create', 'build', 'make', 'develop', 'app', 'application', 'for', 'a', 'an', 'the'}
        for word in words:
            if word not in stop_words and len(word) > 2:
                meaningful_words.extend(word.split())
        
        if meaningful_words:
            # Take up to 3 meaningful words
            name = '-'.join(meaningful_words[:3])
        else:
            # Fallback to prompt-based slug
            name = re.sub(r'[^a-z0-9]+', '-', prompt.lower())
            name = name[:30].strip('-')
        
        return name or "generated-project"

    def _is_valid_project_name(self, name: str) -> bool:
        """Check if project name is valid."""
        if not name or len(name) > 50:
            return False
        # Allow letters, numbers, hyphens
        return bool(re.match(r'^[a-z0-9]+(?:-[a-z0-9]+)*$', name))

    def _create_fallback_structure(self, prompt: str) -> Dict[str, Any]:
        """Create intelligent fallback structure based on prompt keywords."""
        prompt_lower = prompt.lower()
        
        # Detect project type
        if any(word in prompt_lower for word in ['ios', 'swift', 'iphone', 'ipad']):
            return self._ios_fallback_structure(prompt)
        elif any(word in prompt_lower for word in ['web', 'react', 'javascript', 'html']):
            return self._web_fallback_structure(prompt)
        elif any(word in prompt_lower for word in ['api', 'backend', 'server', 'rest']):
            return self._api_fallback_structure(prompt)
        else:
            return self._generic_fallback_structure(prompt)

    def _ios_fallback_structure(self, prompt: str) -> Dict[str, Any]:
        """Fallback structure for iOS projects."""
        project_name = self._validate_project_name(None, prompt)
        return {
            "project_name": project_name,
            "description": f"iOS application: {prompt}",
            "architecture": {
                "type": "ios-app",
                "framework": "swiftui",
                "patterns": ["mvvm"]
            },
            "folders": ["Sources", "Tests", "Resources", "Preview Content"],
            "files": {
                "README.md": f"# {project_name}\n\niOS application generated from prompt: {prompt}",
                "Package.swift": f"""// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "{project_name}",
    platforms: [.iOS(.v16)],
    products: [.app(name: "{project_name}", targets: ["{project_name}"])],
    targets: [.target(name: "{project_name}")]
)""",
                "Sources/App.swift": """import SwiftUI

@main
struct App: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}""",
                "Sources/Views/ContentView.swift": """import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Welcome to Your App")
                .font(.title)
        }
        .padding()
    }
}"""
            }
        }

    def _web_fallback_structure(self, prompt: str) -> Dict[str, Any]:
        """Fallback structure for web projects."""
        project_name = self._validate_project_name(None, prompt)
        return {
            "project_name": project_name,
            "description": f"Web application: {prompt}",
            "architecture": {
                "type": "web-app",
                "framework": "html-css-js",
                "patterns": ["component-based"]
            },
            "folders": ["src", "css", "js", "assets"],
            "files": {
                "README.md": f"# {project_name}\n\nWeb application generated from prompt: {prompt}",
                "index.html": f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{project_name}</title>
    <link rel="stylesheet" href="css/styles.css">
</head>
<body>
    <div id="app">
        <h1>Welcome to {project_name}</h1>
        <p>Your web application is ready!</p>
    </div>
    <script src="js/app.js"></script>
</body>
</html>""",
                "css/styles.css": "body { font-family: Arial, sans-serif; margin: 40px; }",
                "js/app.js": "console.log('Application started');"
            }
        }

    def _api_fallback_structure(self, prompt: str) -> Dict[str, Any]:
        """Fallback structure for API projects."""
        project_name = self._validate_project_name(None, prompt)
        return {
            "project_name": project_name,
            "description": f"API service: {prompt}",
            "architecture": {
                "type": "backend-api",
                "framework": "nodejs",
                "patterns": ["rest"]
            },
            "folders": ["src", "tests", "config"],
            "files": {
                "README.md": f"# {project_name}\n\nAPI service generated from prompt: {prompt}",
                "package.json": f"""{{
  "name": "{project_name}",
  "version": "1.0.0",
  "description": "API service",
  "main": "src/server.js",
  "scripts": {{
    "start": "node src/server.js"
  }}
}}""",
                "src/server.js": """const http = require('http');

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ message: 'API is running' }));
});

server.listen(3000, () => {
  console.log('Server running on port 3000');
});"""
            }
        }

    def _generic_fallback_structure(self, prompt: str) -> Dict[str, Any]:
        """Generic fallback structure for unknown project types."""
        project_name = self._validate_project_name(None, prompt)
        return {
            "project_name": project_name,
            "description": f"Project: {prompt}",
            "architecture": {
                "type": "generic",
                "framework": "standard",
                "patterns": ["modular"]
            },
            "folders": ["src", "tests", "docs", "config"],
            "files": {
                "README.md": f"# {project_name}\n\nProject generated from prompt: {prompt}",
                "project.json": f"""{{
  "name": "{project_name}",
  "description": "Project generated from prompt",
  "version": "1.0.0"
}}"""
            }
        }

    def _write_project_metadata(self, project_root: Path, metadata: Dict[str, Any]):
        """Write project-level metadata file."""
        metadata_file = project_root / ".architect.json"
        metadata_file.write_text(json.dumps(metadata, indent=2))
        self.log(f"[Architect] Wrote project metadata: {metadata_file}")