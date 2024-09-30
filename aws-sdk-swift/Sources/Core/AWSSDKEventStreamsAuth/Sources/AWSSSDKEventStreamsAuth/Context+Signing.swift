//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSSDKHTTPAuth
import ClientRuntime
import Smithy
import SmithyEventStreamsAPI
import SmithyHTTPAPI
import SmithyHTTPAuthAPI
import SmithyIdentity
import SmithyIdentityAPI
import struct Foundation.Date
import struct Foundation.TimeInterval
import SmithyHTTPAuth

extension Context {

    /// Returns the signing config for the event stream message
    /// - Returns: `AWSSigningConfig` for the event stream message
    public func makeEventStreamSigningConfig(date: Date = Date().withoutFractionalSeconds())
    async throws -> AWSSigningConfig {
        let credentials = try await getIdentityResolvers()?
            .get(key: AttributeKey<any IdentityResolver>(name: "aws.auth#sigv4"))?
            .getIdentity(identityProperties: Attributes())
        guard let credentials = credentials as? AWSCredentialIdentity else {
            fatalError("Failed to retrieve AWS credentials for signing event stream messages.")
        }
        guard let service = signingName else {
            fatalError("Signing name must not be nil, it must be set by the middleware during the request")
        }

        guard let region = signingRegion ?? getRegion() else {
            fatalError("Signing region must not be nil, it must be set by the middleware during the request")
        }

        // default flags
        let flags = SigningFlags(useDoubleURIEncode: false,
                                 shouldNormalizeURIPath: false,
                                 omitSessionToken: false)

        return AWSSigningConfig(credentials: credentials,
                                signedBodyValue: .empty, // there is no body, only payload needs to be signed
                                flags: flags,
                                date: date,
                                service: service,
                                region: region,
                                signatureType: .requestEvent,
                                signingAlgorithm: .sigv4)
    }
}
