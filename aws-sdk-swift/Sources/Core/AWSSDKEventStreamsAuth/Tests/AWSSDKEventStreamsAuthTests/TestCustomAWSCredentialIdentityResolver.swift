//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyIdentity

class TestCustomAWSCredentialIdentityResolver: AWSCredentialIdentityResolver {
    let credentials: AWSCredentialIdentity

    init(credentials: AWSCredentialIdentity) {
        self.credentials = credentials
    }

    convenience init() {
        self.init(credentials: AWSCredentialIdentity(
            accessKey: "AKIDEXAMPLE",
            secret: "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY",
            expiration: .init(timeIntervalSinceNow: 30)
        ))
    }

    func getIdentity(identityProperties: Attributes?) async throws -> AWSCredentialIdentity {
        return AWSCredentialIdentity(
            accessKey: "AKIDEXAMPLE",
            secret: "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY",
            expiration: .init(timeIntervalSinceNow: 30)
        )
    }
}
