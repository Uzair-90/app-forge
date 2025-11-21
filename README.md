# APP-FORGE

**APP-FORGE** is an AI-powered agentic system that generates complete Xcode projects from natural-language prompts. Users describe the app they want, and APP-FORGE automatically creates the full project — including UI, logic, documentation, metadata, and Git history — ready to open in Xcode with no manual coding.

---

## 🚀 Features

- **Natural-Language App Generation**: Describe your app, e.g., "Build a notes app with folder support and iCloud sync," and get a fully functional Xcode project.
- **Update Existing Projects**: Modify projects via prompts like "Add a password reset screen" without touching the code manually.
- **Multi-Agent Architecture**: Specialized agents handle architecture, UI, logic, documentation, and validation.
- **Automated Validation**: Ensures UI and logic consistency, correct metadata, and error-free project generation.
- **Metadata Tracking**: `.agent_metadata.json` tracks agent ownership, dependencies, component types, and Git history.
- **Git Integration**: Every agent action commits automatically, allowing rollbacks and progress tracking.
- **Local macOS Coordinator**: Syncs cloud output to your Mac, writes files, updates metadata, and opens Xcode automatically.

---

## ⚙️ Getting Started

### Prerequisites
- macOS with Xcode installed
- Node.js (for cloud agents)
- Python/other dependencies for validation scripts
- Git with SSH configured

### Usage
1. Open the **APP-FORGE macOS App**.
2. Enter your natural-language prompt describing the app.
3. The Coordinator sends the prompt to the cloud orchestrator.
4. Agents generate project skeleton, UI, logic, documentation, and perform validation.
5. Once complete, the Coordinator writes the project locally and opens it in Xcode.

---

## 🔄 Update Workflow
- Send a new prompt describing updates.
- Only affected components are regenerated.
- Validator ensures the updated project is consistent.
- Coordinator syncs updated files locally.

---

## 📌 Metadata & Git
- `.agent_metadata.json` tracks component ownership, dependencies, type, and last modified timestamp.
- Every agent action = Git commit for full traceability.

---
