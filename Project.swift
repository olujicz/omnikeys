import ProjectDescription

let bundleID = "rs.in.olujic.omnikeys"
let macOS14 = DeploymentTargets.macOS("14.0")

let project = Project(
    name: "OmniKeys",
    options: .options(automaticSchemesOptions: .disabled),
    packages: [
        .remote(url: "https://github.com/dduan/TOMLDecoder", requirement: .exact("0.4.5")),
    ],
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
            "MARKETING_VERSION": "1.0.0",
            "CURRENT_PROJECT_VERSION": "1",
            "DEAD_CODE_STRIPPING": "YES",
            // CI flips OMNIKEYS_WARNINGS_AS_ERRORS; a command-line SWIFT_TREAT_WARNINGS_AS_ERRORS would also hit
            // packages (TOMLDecoder builds with -suppress-warnings, which conflicts).
            "SWIFT_TREAT_WARNINGS_AS_ERRORS": "$(OMNIKEYS_WARNINGS_AS_ERRORS)",
            "OMNIKEYS_WARNINGS_AS_ERRORS": "NO",
        ],
        configurations: [
            .debug(name: "Debug", xcconfig: "Config/Signing.xcconfig"),
            .release(
                name: "Release",
                settings: ["SWIFT_TREAT_WARNINGS_AS_ERRORS": "YES"],
                xcconfig: "Config/Signing.xcconfig"
            ),
        ]
    ),
    targets: [
        .target(
            name: "OmniKeys",
            destinations: .macOS,
            product: .app,
            bundleId: bundleID,
            deploymentTargets: macOS14,
            infoPlist: .extendingDefault(with: [
                "LSUIElement": true,
                "CFBundleDisplayName": "OmniKeys",
                "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                "LSApplicationCategoryType": "public.app-category.utilities",
                "NSHumanReadableCopyright": "© 2026 Zoran Olujic. MIT License.",
            ]),
            sources: ["Sources/OmniKeys/**"],
            resources: ["Sources/OmniKeys/Resources/**"],
            entitlements: "packaging/OmniKeys.entitlements",
            dependencies: [.target(name: "OmniKeysCore")],
            settings: .settings(base: [
                "ENABLE_HARDENED_RUNTIME": "YES",
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            ])
        ),
        .target(
            name: "OmniKeysCore",
            destinations: .macOS,
            product: .framework,
            bundleId: "\(bundleID).core",
            deploymentTargets: macOS14,
            sources: ["Sources/OmniKeysCore/**"],
            dependencies: [.package(product: "TOMLDecoder")]
        ),
        .target(
            name: "OmniKeysCoreTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "\(bundleID).core-tests",
            deploymentTargets: macOS14,
            sources: ["Tests/OmniKeysCoreTests/**/*.swift"],
            resources: ["Tests/OmniKeysCoreTests/Fixtures/**"],
            dependencies: [.target(name: "OmniKeysCore")]
        ),
        .target(
            name: "OmniKeysTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "\(bundleID).tests",
            deploymentTargets: macOS14,
            sources: ["Tests/OmniKeysTests/**"],
            dependencies: [.target(name: "OmniKeys")]
        ),
    ],
    schemes: [
        .scheme(
            name: "OmniKeys",
            shared: true,
            buildAction: .buildAction(targets: ["OmniKeys"]),
            testAction: .targets(["OmniKeysCoreTests", "OmniKeysTests"]),
            runAction: .runAction(executable: "OmniKeys"),
            archiveAction: .archiveAction(configuration: "Release")
        ),
    ]
)
