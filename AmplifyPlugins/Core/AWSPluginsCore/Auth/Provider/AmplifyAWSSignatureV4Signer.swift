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
                            date: ClientRuntime.Date) throws -> SdkHttpRequest?
}

public class AmplifyAWSSignatureV4Signer: AWSSignatureV4Signer {
    let group = DispatchGroup()
    
    public init() {
    }
    
    public func sigV4SignedRequest(requestBuilder: SdkHttpRequestBuilder,
                                   credentialsProvider: CredentialsProvider,
                                   signingName: Swift.String,
                                   signingRegion: Swift.String,
                                   date: ClientRuntime.Date) throws -> SdkHttpRequest? {
        do {
            let credentialsResult = try credentialsProvider.getCredentials()
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
            group.enter()
            var httpRequest: SdkHttpRequest? = nil
            let update: (SdkHttpRequest?) -> Void = {
                httpRequest = $0
                self.group.leave()
            }
            Task {
                let value = await AWSSigV4Signer.sigV4SignedRequest(requestBuilder: requestBuilder, signingConfig: signingConfig)
                update(value)
            }
            _ = group.wait(timeout: .distantFuture)

            return httpRequest
        } catch let error {
            throw AuthError.unknown("Unable to sign request", error)
        }
    }
}
