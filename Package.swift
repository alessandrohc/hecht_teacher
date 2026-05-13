// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HechtTeacher",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "HechtTeacher",
            path: "Sources/HechtTeacher"
        )
    ]
)
