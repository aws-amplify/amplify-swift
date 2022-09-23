//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import PackagePlugin

@main
struct SwiftLintPlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) async throws -> [Command] {
        print(context.pluginWorkDirectory)
        return [
            .buildCommand(
                displayName: "Linting \(target.name)",
                executable: try context.tool(named: "swiftlint").path,
                arguments: [
                    "lint",
                    "--in-process-sourcekit",
                    "--cache-path",
                    "\(context.pluginWorkDirectory)",
                    "--config",
                    "\(context.package.directory.string)/Plugins/SwiftLintPlugin/swiftlint.yml",
//                    "--path",
                    target.directory.string

                ],
                environment: [:]
            )
        ]
    }
}
