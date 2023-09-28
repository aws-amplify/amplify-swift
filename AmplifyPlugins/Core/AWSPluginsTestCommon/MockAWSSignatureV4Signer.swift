//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
import ClientRuntime
import AWSClientRuntime
import Foundation

class MockAWSSignatureV4Signer: AWSSignatureV4Signer {
    func sigV4SignedRequest(requestBuilder: SdkHttpRequestBuilder,
                            credentialsProvider: CredentialsProviding,
                            signingName: String,
                            signingRegion: String,
                            date: Date) throws -> SdkHttpRequest? {
        let originalRequest = requestBuilder.build()
        return originalRequest
    }
}
