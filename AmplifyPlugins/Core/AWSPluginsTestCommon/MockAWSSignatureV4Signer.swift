//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import AWSPluginsCore
import ClientRuntime
import Foundation
import InternalAmplifyCredentials

class MockAWSSignatureV4Signer: AWSSignatureV4Signer {
    func sigV4SignedRequest(requestBuilder: SdkHttpRequestBuilder,
                            credentialsProvider: CredentialsProviding,
                            signingName: String,
                            signingRegion: String,
                            date: Date) throws -> SdkHttpRequest?
    {
        let originalRequest = requestBuilder.build()
        return originalRequest
    }
}
