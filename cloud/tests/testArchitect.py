import asyncio
from agents.architect.ArchitectMain import ArchitectAgent

async def test_architect():
    storage_path = "storage_test"
    architect = ArchitectAgent("Architect", storage_path)

    prompt = "Build a notes app with folders"
    metadata = {}

    result = await architect.perform_task(prompt, metadata)
    print("File changes returned by agent:", result)

if __name__ == "__main__":
    asyncio.run(test_architect())
