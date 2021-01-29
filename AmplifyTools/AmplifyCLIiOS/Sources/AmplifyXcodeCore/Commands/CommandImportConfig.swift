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
        if environment.directoryExists(atPath: "amplify") {
            return .success("Amplify project found")
        }

        return .failure(AmplifyCommandError(
                            .folderNotFound,
                            error: nil,
                            recoverySuggestion: "Please run `amplify init` to initialize an Amplify project."))
    }

    static func configFilesExist(
        environment: AmplifyCommandEnvironment,
        args: CommandImportConfig.TaskArgs) -> AmplifyCommandTaskResult {
        for file in args.configFiles {
            if !environment.fileExists(atPath: file) {
                return .failure(AmplifyCommandError(
                    .fileNotFound,
                    error: nil,
                    recoverySuggestion: "\(file) not found."
                ))
            }
        }
        return .success("Config files found")
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
                                                   toGroup: args.configGroup)
            return .success("Successfully updated project \(projectPath)")
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

    public static var description = "Import Amplify configuration files"

    public var taskArgs = CommandImportConfigArgs()

    public var tasks: [AmplifyCommandTask<CommandImportConfigArgs>] = [
        .run(ImportConfigTasks.amplifyFolderExist),
        .run(ImportConfigTasks.configFilesExist),
        .run(ImportConfigTasks.addConfigFilesToXcodeProject)
    ]
    
    public init() {}

    public func onFailure() {
    }
}
