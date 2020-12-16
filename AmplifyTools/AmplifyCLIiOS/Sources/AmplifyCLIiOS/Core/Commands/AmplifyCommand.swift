//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// An `AmplifyCommand` describes the shape of a command. A command it's just an abstraction and doesn't
/// make any assumptions about neither the environment in which will be executed or the executor interface.
/// It's the executor responsibility to provide the necessary arguments to the initializer of a conforming type.
///
/// - `taskArgs`: type defining extra arguments that will be passed to each task
/// - `tasks`: array of tasks whose a command is composed of
/// - `description`: human-readable description of command purpose
protocol AmplifyCommand {
    associatedtype TaskArgs
    var taskArgs: TaskArgs { get }

    var tasks: [AmplifyCommandTask<TaskArgs>] { get }

    static var description: String { get }

    func onFailure()
}
