//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum ImportConfigTasks {
    static func amplifyFolderExist(
        environment: AmplifyCommandEnvironment,
        args: CommandImportConfig.TaskArgs) -> AmplifyCommandTaskResult {
        guard environment.directoryExists(atPath: "amplify") else {
            return .failure(AmplifyCommandError(
                                .folderNotFound,
                                errorDescription: "Amplify project not found at \(environment.basePath).",
                                recoverySuggestion: "Run `amplify init` to initialize an Amplify project."))
        }
        return .success("Amplify project found.")
    }

    static func configFilesExist(
        environment: AmplifyCommandEnvironment,
        args: CommandImportConfig.TaskArgs) -> AmplifyCommandTaskResult {
        for file in args.configFiles {
            if !environment.fileExists(atPath: file) {
                return .failure(AmplifyCommandError(
                    .fileNotFound,
                    errorDescription: "\(file) not found.",
                    recoverySuggestion: "Verify the current Amplify project has been initialized successfully."))
            }
        }
        return .success("Amplify config files found.")
    }

    static func addConfigFilesToXcodeProject(
        environment: AmplifyCommandEnvironment,
        args: CommandImportConfig.TaskArgs) -> AmplifyCommandTaskResult {
        let configFiles = args.configFiles.map {
            environment.createXcodeFile(withPath: environment.path(for: $0), ofType: .resource)
        }
        let projectPath = environment.basePath
        do {
            try environment.addFilesToXcodeProject(projectPath: projectPath,
                                                   files: configFiles,
                                                   toGroup: args.configGroup,
                                                   inTarget: .primary)
            return .success("Successfully updated project \(projectPath).")
        } catch {
            if let underlyingError = error as? AmplifyCommandError {
                return .failure(underlyingError)
            }
            return .failure(AmplifyCommandError(.unknown, error: error))
        }
    }
}

/// Given an existing Amplify iOS project, adds amplify configuration files to a `AmplifyConfig` group
public struct CommandImportConfig: AmplifyCommand {
    public struct CommandImportConfigArgs {
        let configGroup = "AmplifyConfig"
        let configFiles = ["awsconfiguration.json", "amplifyconfiguration.json"]
    }

    public typealias TaskArgs = CommandImportConfigArgs

    public static let description = "Import Amplify configuration files"

    public let taskArgs = CommandImportConfigArgs()

    public let tasks: [AmplifyCommandTask<CommandImportConfigArgs>] = [
        .run(ImportConfigTasks.amplifyFolderExist),
        .run(ImportConfigTasks.configFilesExist),
        .run(ImportConfigTasks.addConfigFilesToXcodeProject)
    ]

    public init() {}
}
