//
// Copyright 2018-2021 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

typealias AmplifyCommandTaskResult = Result<String, AmplifyCommandError>
typealias AmplifyCommandTaskExecutor<TaskArgs> = (AmplifyCommandEnvironment, TaskArgs) -> AmplifyCommandTaskResult

enum AmplifyCommandTask<TaskArgs> {
    case run(AmplifyCommandTaskExecutor<TaskArgs>)
}
