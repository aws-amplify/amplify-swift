//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

typealias AmplifyCommandTaskSuccess = String
typealias AmplifyCommandTaskResult = Result<AmplifyCommandTaskSuccess, AmplifyCommandError>
typealias AmplifyCommandTaskExecutor<TaskArgs> = (AmplifyCommandEnvironment, TaskArgs) -> AmplifyCommandTaskResult

enum AmplifyCommandTask<TaskArgs> {
    case run(AmplifyCommandTaskExecutor<TaskArgs>)
}
