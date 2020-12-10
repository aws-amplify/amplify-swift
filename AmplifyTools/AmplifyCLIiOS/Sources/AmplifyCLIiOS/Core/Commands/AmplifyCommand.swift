//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Describes a command and its structure.
/// - `taskArgs`: type defining
/// - `tasks`: array of tasks whose a command is composed of
/// - `description`: human-readable description of command purpose
protocol AmplifyCommand {
    associatedtype TaskArgs
    var taskArgs: TaskArgs { get }

    var tasks: [AmplifyCommandTask<TaskArgs>] { get }

    static var description: String { get }

    func onFailure()
}
