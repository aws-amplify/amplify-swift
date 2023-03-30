//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import Foundation

class MockCredentialsProvider: CredentialsProvider {
    func getCredentials() async throws -> AWSCredentials {
        return AWSCredentials(
            accessKey: "accessKey",
            secret: "secret",
            expirationTimeout: 1000
        )
    }
}
