//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Attributes
import struct SmithyIdentity.AWSCredentialIdentity
import protocol SmithyIdentity.AWSCredentialIdentityResolver

struct MockAWSCredentialIdentityResolver: AWSCredentialIdentityResolver {
    let _getIdentity: () async throws -> AWSCredentialIdentity
    init(_ _getIdentity: @escaping () async throws -> AWSCredentialIdentity) {
        self._getIdentity = _getIdentity
    }
    init() {
        self._getIdentity = {
            AWSCredentialIdentity(
                accessKey: "some_access_key",
                secret: "some_secret"
            )
        }
    }
    func getIdentity(identityProperties: Attributes?) async throws -> AWSCredentialIdentity {
        try await _getIdentity()
    }
}
