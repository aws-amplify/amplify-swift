//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Defines requirements needed by a command to be executable.
/// The executor, a command definition and the entity providing the environment are decoupled in order
/// to favor re-usability.
public protocol CommandExecutable where Self: CommandEnvironmentProvider {
    func exec<Command: AmplifyCommand>(command: Command) -> AmplifyCommandResult
}

/// Provides a default implementation for an executable command
public extension CommandExecutable {
    private func exec<TaskArgs>(_ task: AmplifyCommandTaskExecutor<TaskArgs>,
                                args: TaskArgs,
                                prevResults: inout [AmplifyCommandTaskResult]) -> Bool {
        let output = task(environment, args)
        switch output {
        case .failure:
            prevResults.append(output)
            return false
        case .success:
            prevResults.append(output)
            return true
        }
    }

    /// Given a command, executes its underlying tasks and aggregates the final result
    func exec<Command: AmplifyCommand>(command: Command) -> AmplifyCommandResult {
        var results: [AmplifyCommandTaskResult] = []

        for task in command.tasks {
            switch task {
            case .run(let run):
                let succeeded = exec(run, args: command.taskArgs, prevResults: &results)
                if !succeeded {
                    return .failure(AmplifyCommandError(from: results))
                }
            }
        }

        return .success(results)
    }
}
