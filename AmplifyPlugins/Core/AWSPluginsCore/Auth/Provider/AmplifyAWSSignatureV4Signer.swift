//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

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
            return AWSSigV4Signer.sigV4SignedRequest(requestBuilder: requestBuilder, signingConfig: signingConfig)
        } catch let err {
            throw AuthError.unknown("Unable to sign request", err)
        }
    }
}
