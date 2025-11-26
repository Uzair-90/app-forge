// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "iCloudNotesApp",
    platforms: [.iOS(.v16)],
    products: [.app(name: "iCloudNotesApp", targets: ["iCloudNotesApp"])],
    targets: [.target(name: "iCloudNotesApp")]
)