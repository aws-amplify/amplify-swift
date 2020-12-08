//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Provides a default implementation for an executable command
protocol CommandExecutable where Self: CommandEnvironmentProvider {
    func exec<T: AmplifyCommand>(command: T) -> AmplifyCommandResult
}

extension CommandExecutable {
    private func precondition<T>(_ task: AmplifyCommandTaskExecutor<T>,
                                 args: T,
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

    private func exec<T>(_ task: AmplifyCommandTaskExecutor<T>,
                         args: T,
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

    private func exec<T>(_ task: AmplifyCommandTaskExecutor<T>,
                         if precondition: AmplifyCommandTaskExecutor<T>,
                         args: T,
                         prevResults: inout [AmplifyCommandTaskResult]) -> Bool {
        let shouldRun = precondition(environment, args)
        switch shouldRun {
        case .failure:
            prevResults.append(shouldRun)
            return false
        case .success:
            return exec(task, args: args, prevResults: &prevResults)
        }
    }

    private func exec<T>(_ task: AmplifyCommandTaskExecutor<T>,
                         skipIf check: AmplifyCommandTaskExecutor<T>,
                         args: T,
                         prevResults: inout [AmplifyCommandTaskResult]) -> Bool {
        let shouldSkip = check(environment, args)
        switch shouldSkip {
        case .failure:
            return exec(task, args: args, prevResults: &prevResults)
        case .success:
            prevResults.append(shouldSkip)
            return true
        }
    }

    /// Given a command, executes its underlying tasks and aggregates the final result
    func exec<T: AmplifyCommand>(command: T) -> AmplifyCommandResult {
        var succeeded = false
        let serialQueue = DispatchQueue(label: "com.amazon.amplify")
        var results: [AmplifyCommandTaskResult] = []

        for task in command.tasks {
            serialQueue.sync {
                switch task {
                case .precondition(let run):
                    succeeded = precondition(run, args: command.taskArgs, prevResults: &results)
                    if !succeeded {
                        break
                    }
                case .runWithPrecondition(let run, precondition: let precondition):
                    succeeded = exec(run, if: precondition, args: command.taskArgs, prevResults: &results)
                    if !succeeded {
                        break
                    }

                case .runOrSkip(let run, skipIf: let skipIf):
                    succeeded = exec(run, skipIf: skipIf, args: command.taskArgs, prevResults: &results)

                case .run(let run):
                    succeeded = exec(run, args: command.taskArgs, prevResults: &results)
                }
            }
        }

        return succeeded ? .success(results) : .failure(AmplifyCommandError(from: results))
    }
}
