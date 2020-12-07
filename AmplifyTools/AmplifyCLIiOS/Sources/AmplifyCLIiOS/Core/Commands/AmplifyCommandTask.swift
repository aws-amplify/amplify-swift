//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

typealias AmplifyCommandTaskResult = Result<String, AmplifyCommandError>
typealias AmplifyCommandTaskExecutor<T> = (AmplifyCommandEnvironment, T) -> AmplifyCommandTaskResult

enum AmplifyCommandTask<T> {
    // halt command execution if executor fails
    case precondition(AmplifyCommandTaskExecutor<T>)

    // halt command execution if precondition fails
    case runWithPrecondition(AmplifyCommandTaskExecutor<T>, precondition: AmplifyCommandTaskExecutor<T>)

    // skip command execution if skip fails but let commmand keep going
    case runOrSkip(AmplifyCommandTaskExecutor<T>, skipIf: AmplifyCommandTaskExecutor<T>)

    // if exeuctor fails, let command keep going
    case run(AmplifyCommandTaskExecutor<T>)
}
