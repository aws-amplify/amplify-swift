//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit
import ClientRuntime

// TODO: support more config options that are required to be supported when the CRT adds the ability to pass them down.
public struct IMDSConfig {
    let retries: Int
    public init(retries: Int = 3) {
        self.retries = retries
    }
}
