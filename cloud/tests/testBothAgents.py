# testBothAgents.py
import json
import time
from pathlib import Path
from agents.architect.ArchitectMain import ArchitectMain
from agents.uiAgent.UIAgent import UIModelAgent

def main():
    print("Starting iOS App Generation Pipeline...")

    # ----------------------------
    # ORIGINAL USER REQUEST
    # ----------------------------
    user_request = "Build me a Scientific Calculator App for iOS"

    # ----------------------------
    # 1. ARCHITECT AGENT PHASE
    # ----------------------------
    print("\n1. Creating project architecture...")
    architect = ArchitectMain()
    arch_result = architect.perform_task(user_request)

    print(f"   ✓ Created project: {arch_result['app_name']}")
    print(f"   ✓ Generated {len(arch_result['file_changes'])} base files")

    # Wait for metadata to flush
    time.sleep(0.5)

    # ----------------------------
    # METADATA CHECK (optional)
    # ----------------------------
    metadata_path = Path("storage/metadata.json")
    if metadata_path.exists():
        print(f"\n   📋 Found metadata file: {metadata_path}")

        with open(metadata_path, "r") as f:
            metadata = json.load(f)

        if "phases" not in metadata:
            print(f"   📋 Metadata is OLD format")
            print(f"   📋 Total entries: {len(metadata)}")

            app_names = {path.split("/")[0] for path in metadata.keys()}
            print(f"   📋 App names detected: {app_names}")

            last_key = list(metadata.keys())[-1]
            last_app = last_key.split("/")[0]

            clean_arch_name = arch_result["app_name"].replace(" ", "")
            if clean_arch_name != last_app:
                print("   ⚠️  Mismatch in metadata app name!")
                print(f"      Architect: {clean_arch_name}")
                print(f"      Metadata : {last_app}")

    # ----------------------------
    # 2. UI AGENT PHASE
    # ----------------------------
    print("\n2. Creating UI components...")
    try:
        ui_agent = UIModelAgent()

        print(f"   🐛 UIAgent storage path: {ui_agent.storage_path}")

        # ⬅️ Pass the SAME user request so UI agent follows the same app description
        ui_result = ui_agent.perform_task(
            f"""
            Generate UI for this app:

            {user_request}

            Create all necessary screens, components, views, themes,
            and UI logic according to the project structure generated
            by the Architect Agent.
            """
        )

        print(f"   ✓ UI components created: {len(ui_result['file_changes'])}")
        print(f"   ✓ UIAgent used app: {ui_result.get('app_name', 'Unknown')}")

    except Exception as e:
        print(f"   ✗ UIModelAgent failed: {e}")
        import traceback
        traceback.print_exc()

        # ----------------------------
        # FALLBACK: Minimal UI so Xcode can build
        # ----------------------------
        print("\n   🛠️  Running fallback UI generator...")

        try:
            app_name = arch_result["app_name"]
            clean_name = app_name.replace(" ", "")

            calculator_view = """import SwiftUI

struct CalculatorView: View {
    @State private var display: String = "0"

    let buttons: [[String]] = [
        ["7", "8", "9", "/"],
        ["4", "5", "6", "*"],
        ["1", "2", "3", "-"],
        ["0", ".", "=", "+"]
    ]

    var body: some View {
        VStack {
            Text(display)
                .font(.largeTitle)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()

            ForEach(buttons, id: \.self) { row in
                HStack {
                    ForEach(row, id: \.self) { label in
                        Button(action: {
                            buttonPressed(label)
                        }) {
                            Text(label)
                                .font(.title)
                                .frame(width: 70, height: 70)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding()
    }

    func buttonPressed(_ label: String) {
        if display == "0" {
            display = label
        } else {
            display += label
        }
    }
}

struct CalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        CalculatorView()
    }
}
"""

            ui_agent.write_file(
                f"{clean_name}/Sources/UI/CalculatorView.swift",
                calculator_view
            )

            print("   ✓ Created CalculatorView.swift fallback UI")

            ui_result = {
                "file_changes": {
                    f"{clean_name}/Sources/UI/CalculatorView.swift": {"type": "created"}
                }
            }

        except Exception as e2:
            print(f"   ✗ Fallback UI creation also failed: {e2}")
            ui_result = {"file_changes": {}}

    # ----------------------------
    # 3. SUMMARY + FILE LIST
    # ----------------------------
    print("\n" + "=" * 60)
    print("🎉 GENERATION COMPLETE!")
    print("=" * 60)

    print(f"Project: {arch_result['app_name']}")
    clean_name = arch_result["app_name"].replace(" ", "")
    print(f"Location: storage/{clean_name}/")

    total_files = len(arch_result["file_changes"]) + len(ui_result["file_changes"])
    print(f"Total files: {total_files}")

    project_dir = Path("storage") / clean_name

    if project_dir.exists():
        swift_files = [str(p.relative_to(project_dir)) for p in project_dir.rglob("*.swift")]

        print(f"\nSwift files in project: {len(swift_files)}")
        for file in swift_files:
            print(f"  {file}")

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
