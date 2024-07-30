//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
import AWSClientRuntime
import Foundation

class MockCredentialsProvider: AWSClientRuntime.CredentialsProviding {
    func getCredentials() async throws -> AWSClientRuntime.AWSCredentials {
        return AWSCredentials(
            accessKey: "accessKey",
            secret: "secret",
            expirationTimeout: Date().addingTimeInterval(1000)
        )
    }
}
