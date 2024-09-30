//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Foundation.ProcessInfo

struct ExecutionEnvMetadata {
    let name: String
}

extension ExecutionEnvMetadata: CustomStringConvertible {

    var description: String {
        return "exec-env/\(name.userAgentToken)"
    }

    static func detectExecEnv() -> ExecutionEnvMetadata? {
        guard let execEnv = ProcessInfo.processInfo.environment["AWS_EXECUTION_ENV"], !execEnv.isEmpty else {
            return nil
        }
        return ExecutionEnvMetadata(name: execEnv)
    }
}
