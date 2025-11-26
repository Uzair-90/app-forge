import asyncio
from pathlib import Path
from agents.architect.ArchitectMain import ArchitectAgent

async def test_architect():
    project_root = Path(__file__).resolve().parents[2]  # cloud/
    storage_path = project_root / "storage"

    architect = ArchitectAgent("Architect", storage_path)

    # Test with different project types
    test_prompts = [
        "Build me a notes app with folder support and an iCloud sync option",
        "Create a REST API for user management",
        "Make a weather app for iOS with SwiftUI",
        "Build a task management web application"
    ]

    for i, prompt in enumerate(test_prompts):
        print(f"\n{'='*50}")
        print(f"Test {i+1}: {prompt}")
        print(f"{'='*50}")
        
        metadata = {}
        result = await architect.perform_task(prompt, metadata)
        
        # Print the detailed results
        print("Agent Result:")
        print(f"  Project Name: {result.get('project_name')}")
        print(f"  Description: {result.get('description')}")
        print(f"  Architecture: {result.get('architecture')}")
        print(f"  Project Root: {result.get('project_root')}")
        print(f"  Files Created: {len(result.get('files_created', {}))}")
        
        # Basic assertions
        assert result.get('project_name'), "Project name is missing"
        assert result.get('description'), "Project description is missing"
        assert result.get('architecture'), "Architecture info is missing"
        assert len(result.get('files_created', {})) > 0, "No files were created"
        
        # Verify project folder exists
        project_path = Path(result.get('project_root'))
        assert project_path.exists(), f"Project folder doesn't exist: {project_path}"
        assert project_path.is_dir(), f"Project path is not a directory: {project_path}"
        
        # Check that some expected files exist
        files_created = result.get('files_created', {})
        assert any('README' in file_path for file_path in files_created), "No README file found"
        
        # Verify project metadata file
        architect_metadata = project_path / ".architect.json"
        assert architect_metadata.exists(), f"Project metadata file missing: {architect_metadata}"
        
        print(f"✓ Test {i+1} passed - Project: {result.get('project_name')}")

    # Check storage folder contains multiple projects
    projects = [p for p in storage_path.iterdir() if p.is_dir() and p.name != ".gitkeep"]
    assert len(projects) >= len(test_prompts), f"Expected at least {len(test_prompts)} projects, found {len(projects)}"

    # Check global metadata
    metadata_file = storage_path / "metadata.json"
    assert metadata_file.exists(), "Global metadata.json not found"
    
    # Print summary
    print(f"\n{'='*50}")
    print("TEST SUMMARY")
    print(f"{'='*50}")
    print(f"Total projects created: {len(projects)}")
    print("Project folders:")
    for project in projects:
        # Count files in each project
        file_count = len(list(project.rglob('*')))
        dir_count = len(list(project.rglob('*/')))
        print(f"  - {project.name}: {file_count} files, {dir_count} directories")
        
        # Show project metadata
        architect_meta = project / ".architect.json"
        if architect_meta.exists():
            import json
            meta_data = json.loads(architect_meta.read_text())
            print(f"    Type: {meta_data.get('architecture', {}).get('type', 'unknown')}")
            print(f"    Framework: {meta_data.get('architecture', {}).get('framework', 'unknown')}")

    print(f"Global metadata at: {metadata_file}")
    print("All tests completed successfully!")

def cleanup_test_projects():
    """Optional cleanup function to remove test projects"""
    project_root = Path(__file__).resolve().parents[2]
    storage_path = project_root / "storage"
    
    # Remove test projects (be careful with this in production!)
    test_projects = [
        "notes-app-folder", "notes-folder-icloud", "notes-icloud-sync",
        "user-management-api", "user-management", "management-api",
        "weather-app-ios", "weather-ios-swiftui", "ios-weather-swiftui",
        "task-management-web", "management-web-application", "web-application"
    ]
    
    for project in test_projects:
        project_path = storage_path / project
        if project_path.exists():
            import shutil
            shutil.rmtree(project_path)
            print(f"Cleaned up: {project}")

if __name__ == "__main__":
    # Uncomment the line below if you want to clean up before testing
    # cleanup_test_projects()
    
    asyncio.run(test_architect())