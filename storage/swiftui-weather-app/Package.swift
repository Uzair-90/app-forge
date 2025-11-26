// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SwiftUIWeatherApp",
    platforms: [.iOS(.v14)],
    products: [.app(name: "SwiftUIWeatherApp", targets: ["SwiftUIWeatherApp"])],
    targets: [.target(name: "SwiftUIWeatherApp")]
)