//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

//import AWSClientRuntime
import Foundation
@testable import AWSPluginsCore

class MockCredentialsProvider: CredentialsProvider {
    func fetchCredentials() async throws -> Credentials {
        return Credentials(
            accessKey: "accessKey",
            secret: "secret",
            expirationTimeout: Date().addingTimeInterval(1000),
            sessionToken: "token"
        )
    }
}
