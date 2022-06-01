//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import ClientRuntime
import AWSClientRuntime
import AwsCommonRuntimeKit

public protocol AWSSignatureV4Signer {
    func sigV4SignedRequest(requestBuilder: SdkHttpRequestBuilder,
                            credentialsProvider: CredentialsProvider,
                            signingName: Swift.String,
                            signingRegion: Swift.String,
                            date: ClientRuntime.Date) async throws -> SdkHttpRequest?
}

public class AmplifyAWSSignatureV4Signer: AWSSignatureV4Signer {
    public init() {
    }
    
    public func sigV4SignedRequest(requestBuilder: SdkHttpRequestBuilder,
                                   credentialsProvider: CredentialsProvider,
                                   signingName: Swift.String,
                                   signingRegion: Swift.String,
                                   date: ClientRuntime.Date) async throws -> SdkHttpRequest? {
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
                                                 signatureType: .requestHeaders)
            
            let httpRequest = await AWSSigV4Signer.sigV4SignedRequest(requestBuilder: requestBuilder, signingConfig: signingConfig)
            return httpRequest
        } catch let error {
            throw AuthError.unknown("Unable to sign request", error)
        }
    }
}
