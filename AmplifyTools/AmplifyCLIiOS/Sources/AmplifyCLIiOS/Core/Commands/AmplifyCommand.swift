//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AmplifyCommand {
    associatedtype TaskArgs
    var taskArgs: TaskArgs { get }

    var tasks: [AmplifyCommandTask<TaskArgs>] { get }

    static var description: String { get }

    func onFailure()
}
