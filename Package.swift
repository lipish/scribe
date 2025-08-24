// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Scribe",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Scribe",
            targets: ["Scribe"]
        )
    ],
    dependencies: [
        // 添加依赖项
    ],
    targets: [
        .executableTarget(
            name: "Scribe",
            dependencies: [],
            path: "Scribe",
            sources: [
                "ScribeApp.swift",
                "ContentView.swift",
                "Models/Persistence.swift",
                "Models/Document+CoreDataClass.swift",
                "Models/Document+CoreDataProperties.swift",
                "Models/Cell+CoreDataClass.swift",
                "Models/Cell+CoreDataProperties.swift",
                "Models/AIResponse+CoreDataClass.swift",
                "Models/AIResponse+CoreDataProperties.swift",
                "Models/Tag+CoreDataClass.swift",
                "Models/Tag+CoreDataProperties.swift",
                "ViewModels/DocumentViewModel.swift",
                "Views/DocumentEditorView.swift",
                "Views/DocumentManagementView.swift",
                "Views/RichTextEditor.swift",
                "Views/JupyterCellView.swift",
                "Views/DocumentExportView.swift",
                "Views/Settings/AISettingsView.swift",
                "Services/AIService.swift",
                "Services/DocumentExportService.swift"
            ],
            resources: [
                .process("Assets.xcassets"),
                .process("Scribe.xcdatamodeld")
            ]
        )
    ]
)