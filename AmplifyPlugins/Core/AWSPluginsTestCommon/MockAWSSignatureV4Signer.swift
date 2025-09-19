//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import AwsCommonRuntimeKit
import AWSPluginsCore
import AWSPluginsCore
import Foundation
import InternalAmplifyCredentials
import SmithyHTTPAPI
import SmithyIdentity

class MockAWSSignatureV4Signer: AWSSignatureV4Signer {
    func sigV4SignedRequest(
        requestBuilder: SmithyHTTPAPI.HTTPRequestBuilder,
        credentialIdentityResolver: some AWSCredentialIdentityResolver,
        signingName: String,
        signingRegion: String,
        date: Date
    ) throws -> SmithyHTTPAPI.HTTPRequest? {
        let originalRequest = requestBuilder.build()
        return originalRequest
    }
}
