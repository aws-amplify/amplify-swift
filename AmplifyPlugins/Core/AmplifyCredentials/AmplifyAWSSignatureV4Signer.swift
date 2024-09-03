//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSClientRuntime
import AwsCommonRuntimeKit
import ClientRuntime
import Foundation

public protocol AWSSignatureV4Signer {
    func sigV4SignedRequest(requestBuilder: SdkHttpRequestBuilder,
                            credentialsProvider: AWSClientRuntime.CredentialsProviding,
                            signingName: Swift.String,
                            signingRegion: Swift.String,
                            date: ClientRuntime.Date) async throws -> SdkHttpRequest?
}

public class AmplifyAWSSignatureV4Signer: AWSSignatureV4Signer {
    public init() {
    }

    public func sigV4SignedRequest(requestBuilder: SdkHttpRequestBuilder,
                                   credentialsProvider: AWSClientRuntime.CredentialsProviding,
                                   signingName: Swift.String,
                                   signingRegion: Swift.String,
                                   date: ClientRuntime.Date) async throws -> SdkHttpRequest?
    {
        do {
            let credentials = try await credentialsProvider.getCredentials()

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
                                                 signatureType: .requestHeaders,
                                                 signingAlgorithm: .sigv4)

            let httpRequest = await AWSSigV4Signer.sigV4SignedRequest(
                requestBuilder: requestBuilder,
                signingConfig: signingConfig
            )
            return httpRequest
        } catch {
            throw AuthError.unknown("Unable to sign request", error)
        }
    }
}
