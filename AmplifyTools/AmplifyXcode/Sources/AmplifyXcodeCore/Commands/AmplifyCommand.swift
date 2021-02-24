//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// An `AmplifyCommand` describes the shape of a command. A command is just an abstraction and doesn't
/// make any assumptions about neither the environment in which will be executed or the executor interface.
/// It's the executor's responsibility to provide the necessary arguments to the initializer of a conforming type.
///
/// - `taskArgs`: type defining extra arguments that will be passed to each task
/// - `tasks`: array of tasks whose a command is composed of
/// - `description`: human-readable description of command purpose
public protocol AmplifyCommand {
    associatedtype TaskArgs
    var taskArgs: TaskArgs { get }

    var tasks: [AmplifyCommandTask<TaskArgs>] { get }

    static var description: String { get }

    func onFailure()
}

// MARK: onFailure default
public extension AmplifyCommand {
    func onFailure() {
        // no-op by default
    }
}
