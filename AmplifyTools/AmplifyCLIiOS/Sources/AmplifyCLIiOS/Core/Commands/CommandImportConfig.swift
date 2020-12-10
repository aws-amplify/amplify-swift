//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

func amplifyFolderExist(
    context: AmplifyCommandEnvironment,
    args: CommandImportConfig.TaskArgs) -> AmplifyCommandTaskResult {
    if context.directoryExists(atPath: "amplify") {
        return .success("Amplify project found")
    }

    return .failure(AmplifyCommandError(
                        .folderNotFound,
                        error: nil,
                        recoverySuggestion: "Please run `amplify init` to initialize an Amplify project."))
}

func addConfigFilesToXcodeProject(
    context: AmplifyCommandEnvironment,
    args: CommandImportConfig.TaskArgs) -> AmplifyCommandTaskResult {
    let configFiles = args.configFiles.map { XcodeProjectFile(context.path(for: $0), type: .resource) }
    let projectPath = context.basePath
    do {
        try context.xcode(project: projectPath, add: configFiles, toGroup: args.configGroup)
        return .success("Successfully updated project \(projectPath)")
    } catch {
        if let underlyingError = error as? AmplifyCommandError {
            return .failure(underlyingError)
        }
        return .failure(AmplifyCommandError(.unknown, error: error))
    }
}

/// Given an existing Amplify iOS project, adds configuration files to a `AmplifyConfig` group
struct CommandImportConfig: AmplifyCommand {
    struct CommandImportConfigArgs {
        let configGroup = "AmplifyConfig"
        let configFiles = ["awsconfiguration.json", "amplifyconfiguration.json"]
    }

    typealias TaskArgs = CommandImportConfigArgs

    static var description = "Import Amplify configuration files"

    var taskArgs = CommandImportConfigArgs()

    var tasks: [AmplifyCommandTask<CommandImportConfigArgs>] = [
        .precondition(amplifyFolderExist),
        .run(addConfigFilesToXcodeProject)
    ]

    func onFailure() {
    }
}
