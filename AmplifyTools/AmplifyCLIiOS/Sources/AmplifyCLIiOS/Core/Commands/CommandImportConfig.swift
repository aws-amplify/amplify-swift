//
// Copyright Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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

    static func addConfigFilesToXcodeProject(
        environment: AmplifyCommandEnvironment,
        args: CommandImportConfig.TaskArgs) -> AmplifyCommandTaskResult {
        let configFiles = args.configFiles.map {
            environment.createXcodeFile(withPath: $0, ofType: .resource)
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
struct CommandImportConfig: AmplifyCommand {
    struct CommandImportConfigArgs {
        let configGroup = "AmplifyConfig"
        let configFiles = ["awsconfiguration.json", "amplifyconfiguration.json"]
    }

    typealias TaskArgs = CommandImportConfigArgs

    static var description = "Import Amplify configuration files"

    var taskArgs = CommandImportConfigArgs()

    var tasks: [AmplifyCommandTask<CommandImportConfigArgs>] = [
        .run(ImportConfigTasks.amplifyFolderExist),
        .run(ImportConfigTasks.addConfigFilesToXcodeProject)
    ]

    func onFailure() {
    }
}
