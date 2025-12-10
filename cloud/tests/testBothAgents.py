# testBothAgents.py (create a new file)
import json
import time
from pathlib import Path
from agents.architect.ArchitectMain import ArchitectMain
from agents.uiAgent.UIAgent import UIModelAgent

def main():
    print("Starting iOS App Generation Pipeline...")

    # Step 1: Create project architecture
    print("\n1. Creating project architecture...")
    architect = ArchitectMain()
    arch_result = architect.perform_task("Build me a Notes Taking App for iOS")

    print(f"   ✓ Created project: {arch_result['app_name']}")
    print(f"   ✓ Generated {len(arch_result['file_changes'])} base files")

    # Let metadata writing complete
    time.sleep(0.5)

    # Debug: Show what's in metadata
    metadata_path = Path("storage/metadata.json")
    if metadata_path.exists():
        print(f"\n   📋 Metadata file exists: {metadata_path}")
        with open(metadata_path, 'r') as f:
            metadata = json.load(f)

        # Check if metadata is old format
        if "phases" not in metadata:
            print(f"   📋 Metadata is in OLD format (flat dictionary)")
            print(f"   📋 Number of entries: {len(metadata)}")

            # Extract all app names
            app_names = set()
            for file_path in metadata.keys():
                parts = file_path.split('/')
                if parts:
                    app_names.add(parts[0])

            print(f"   📋 Found app names: {app_names}")

            # Get the last app (most recent)
            if metadata:
                last_key = list(metadata.keys())[-1]
                last_app = last_key.split('/')[0]
                print(f"   📋 Last app in metadata: {last_app}")
                print(f"   📋 Architect app name: {arch_result['app_name']}")

                # Check if they match
                clean_arch_name = arch_result['app_name'].replace(" ", "")
                if clean_arch_name != last_app:
                    print(f"   ⚠️  WARNING: App names don't match!")
                    print(f"      Architect: {clean_arch_name}")
                    print(f"      Metadata: {last_app}")

    # Step 2: Add UI components
    print("\n2. Adding UI components...")
    try:
        ui_agent = UIModelAgent()

        # Debug: Print what UIAgent will see
        print(f"   🐛 UIAgent storage path: {ui_agent.storage_path}")

        ui_result = ui_agent.perform_task("""
            Create UI for a notes app with:
            - Note list with cards
            - Note editor with formatting
            - Categories and tags
            - Search bar
            - Dark mode
        """)

        print(f"   ✓ Added {len(ui_result['file_changes'])} UI files/components")
        print(f"   ✓ UIAgent used app name: {ui_result.get('app_name', 'Unknown')}")

    except Exception as e:
        print(f"   ✗ UIModelAgent failed: {e}")
        import traceback
        traceback.print_exc()

        # Try to manually create UI files as fallback
        print(f"\n   🛠️  Attempting manual fallback...")
        try:
            # Manually create some UI files
            app_name = arch_result['app_name']
            clean_name = app_name.replace(" ", "")

            # Create a simple note model
            # Note: avoid f-string for the Swift body since it contains many { } braces.
            note_model = f"{clean_name}/Sources/Models/Note.swift\n" + """import SwiftUI
import Foundation

struct Note: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var tags: [String]
    var isPinned: Bool

    init(id: UUID = UUID(), title: String, content: String, tags: [String] = [], isPinned: Bool = false) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
        self.tags = tags
        self.isPinned = isPinned
    }
}

class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var searchText: String = ""

    var filteredNotes: [Note] {
        if searchText.isEmpty {
            return notes
        }
        return notes.filter { note in
            note.title.localizedCaseInsensitiveContains(searchText) ||
            note.content.localizedCaseInsensitiveContains(searchText)
        }
    }

    func addNote(title: String, content: String, tags: [String] = []) {
        let note = Note(title: title, content: content, tags: tags)
        notes.append(note)
    }

    func deleteNote(at indexSet: IndexSet) {
        notes.remove(atOffsets: indexSet)
    }
}
"""

            # Write the file
            ui_agent.write_file(f"{clean_name}/Sources/Models/Note.swift", note_model)
            print(f"   ✓ Created Note.swift as fallback")

            ui_result = {"file_changes": {f"{clean_name}/Sources/Models/Note.swift": {"type": "created"}}}

        except Exception as e2:
            print(f"   ✗ Fallback also failed: {e2}")
            ui_result = {"file_changes": {}}

    # Final summary
    print("\n" + "=" * 60)
    print("🎉 GENERATION COMPLETE!")
    print("=" * 60)
    print(f"Project: {arch_result['app_name']}")

    clean_name = arch_result['app_name'].replace(" ", "")
    print(f"Location: storage/{clean_name}/")

    total_files = len(arch_result['file_changes']) + len(ui_result.get('file_changes', {}))
    print(f"Total files: {total_files}")

    # List all files in the project
    project_dir = Path("storage") / clean_name
    if project_dir.exists():
        swift_files = []
        for p in project_dir.rglob("*.swift"):
            rel_path = p.relative_to(project_dir)
            swift_files.append(str(rel_path))

        yml_files = []
        for yml_file in project_dir.rglob("*.yml"):
            yml_files.append(str(yml_file.relative_to(project_dir)))

        print(f"\nSwift files in project: {len(swift_files)}")
        if swift_files:
            print("  " + "\n  ".join(sorted(swift_files)[:10]))  # Show first 10
            if len(swift_files) > 10:
                print(f"  ... and {len(swift_files) - 10} more")

        if yml_files:
            print(f"\nConfiguration files:")
            for yml in yml_files:
                print(f"  {yml}")

    print("\nTo build:")
    print(f"  cd storage/{clean_name}")
    print("  xcodegen generate")
    print("  open *.xcodeproj")
    print("=" * 60)

    return {
        "architect": arch_result,
        "ui_agent": ui_result
    }

if __name__ == "__main__":
    results = main()
