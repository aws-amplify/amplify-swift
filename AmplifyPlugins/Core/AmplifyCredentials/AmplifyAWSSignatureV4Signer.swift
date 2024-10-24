//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSSDKHTTPAuth
import SmithyHTTPAPI
import SmithyHTTPAuthAPI
import SmithyHTTPAuth
import SmithyIdentity

public protocol AWSSignatureV4Signer {
    func sigV4SignedRequest(requestBuilder: SmithyHTTPAPI.HTTPRequestBuilder,
                            credentialIdentityResolver: some AWSCredentialIdentityResolver,
                            signingName: Swift.String,
                            signingRegion: Swift.String,
                            date: Date) async throws -> SmithyHTTPAPI.HTTPRequest?
}

public class AmplifyAWSSignatureV4Signer: AWSSignatureV4Signer {
    private let signer: AWSSigV4Signer

    public init(signer: AWSSigV4Signer = .init()) {
        self.signer = signer
    }

    public func sigV4SignedRequest(requestBuilder: SmithyHTTPAPI.HTTPRequestBuilder,
                                   credentialIdentityResolver: some AWSCredentialIdentityResolver,
                                   signingName: Swift.String,
                                   signingRegion: Swift.String,
                                   date: Date) async throws -> SmithyHTTPAPI.HTTPRequest? {
        do {
            let credentialIdentity = try await credentialIdentityResolver.getIdentity()

            let flags = SigningFlags(useDoubleURIEncode: true,
                                     shouldNormalizeURIPath: true,
                                     omitSessionToken: false)
            let signedBodyHeader: AWSSignedBodyHeader = .none
            let signedBodyValue: AWSSignedBodyValue = .empty
            let signingConfig = AWSSigningConfig(credentials: credentialIdentity,
                                                 signedBodyHeader: signedBodyHeader,
                                                 signedBodyValue: signedBodyValue,
                                                 flags: flags,
                                                 date: date,
                                                 service: signingName,
                                                 region: signingRegion,
                                                 signatureType: .requestHeaders,
                                                 signingAlgorithm: .sigv4)

            let httpRequest = await signer.sigV4SignedRequest(
                requestBuilder: requestBuilder,
                signingConfig: signingConfig
            )
            return httpRequest
        } catch let error {
            throw AuthError.unknown("Unable to sign request", error)
        }
    }
}
