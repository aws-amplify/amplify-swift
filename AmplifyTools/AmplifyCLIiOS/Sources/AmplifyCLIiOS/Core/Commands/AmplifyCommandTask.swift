//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

typealias AmplifyCommandTaskResult = Result<String, AmplifyCommandError>
typealias AmplifyCommandTaskExecutor<TaskArgs> = (AmplifyCommandEnvironment, TaskArgs) -> AmplifyCommandTaskResult

enum AmplifyCommandTask<TaskArgs> {
    // halt command execution if executor fails
    case precondition(AmplifyCommandTaskExecutor<TaskArgs>)

    // if executor fails, let command keep going
    case run(AmplifyCommandTaskExecutor<TaskArgs>)
}
