//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public typealias AmplifyCommandTaskSuccess = String
public typealias AmplifyCommandTaskResult = Result<AmplifyCommandTaskSuccess, AmplifyCommandError>
public typealias AmplifyCommandTaskExecutor<TaskArgs> = (AmplifyCommandEnvironment, TaskArgs) -> AmplifyCommandTaskResult

public enum AmplifyCommandTask<TaskArgs> {
    case run(AmplifyCommandTaskExecutor<TaskArgs>)
}
