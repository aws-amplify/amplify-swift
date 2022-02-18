//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import AWSS3
import AWSPluginsCore
import ClientRuntime
import AWSClientRuntime

/// The class confirming to AWSS3PreSignedURLBuilderBehavior which uses an instance of the AWSS3PreSignedURLBuilder to
/// perform its methods. This class acts as a wrapper to expose AWSS3PreSignedURLBuilder functionality through an
/// instance over a singleton, and allows for mocking in unit tests. The methods contain no other logic other than
/// calling the same method using the AWSS3PreSignedURLBuilder instance.
class AWSS3PreSignedURLBuilderAdapter: AWSS3PreSignedURLBuilderBehavior {
    let awsS3SigningName = "s3"
    let authService: AWSAuthServiceBehavior
    let signingRegion: String

    /// Creates a pre-signed URL builder.
    /// - Parameter credentialsProvider: Credentials Provider.
    init(authService: AWSAuthServiceBehavior, signingRegion: String) {
        self.authService = authService
        self.signingRegion = signingRegion
    }

    /// Gets pre-signed URL.
    /// - Parameter requestBuilder: request builder
    /// - Returns: Pre-Signed URL
    func getPreSignedURL(_ requestBuilder: SdkHttpRequestBuilder) throws -> URL {
        // TODO: handle clock skew?

        let httpRequest = try sigV4SignedRequest(requestBuilder: requestBuilder,
                                                 signingName: awsS3SigningName,
                                                 signingRegion: signingRegion,
                                                 date: Date())

        guard let preSignedURL = httpRequest.endpoint.url else {
            throw AWSS3PreSignedURLBuilderError.failed(reason: "Failed to get Pre-Signed URL from Endpoint", error: nil)
        }

        return preSignedURL
    }

    internal func sigV4SignedRequest(requestBuilder: SdkHttpRequestBuilder,
                                     signingName: Swift.String,
                                     signingRegion: Swift.String,
                                     date: ClientRuntime.Date) throws -> SdkHttpRequest {
        do {
            let credentialsResult = try authService.getCredentialsProvider().getCredentials()
            let credentials = try credentialsResult.get()

            let flags = SigningFlags(useDoubleURIEncode: true,
                                     shouldNormalizeURIPath: true,
                                     omitSessionToken: false)
            let signedBodyHeader: AWSSignedBodyHeader = .none
            let signedBodyValue: AWSSignedBodyValue = .empty
            let signingConfig = AWSSigningConfig(credentials: credentials,
                                                 signedBodyHeader: signedBodyHeader,
                                                 signedBodyValue: signedBodyValue,
                                                 flags: flags,
                                                 date: date,
                                                 service: signingName,
                                                 region: signingRegion,
                                                 signatureType: .requestHeaders)
            guard let signedRequest = AWSSigV4Signer.sigV4SignedRequest(requestBuilder: requestBuilder, signingConfig: signingConfig) else {
                throw AWSS3PreSignedURLBuilderError.failed(reason: "AWSSigV4Signer did not returned a signed request", error: nil)
            }
            return signedRequest
        } catch let err {
            throw err
        }
    }
}
