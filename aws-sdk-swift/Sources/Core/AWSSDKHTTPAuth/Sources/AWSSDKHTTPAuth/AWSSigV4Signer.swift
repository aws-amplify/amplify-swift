//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class AwsCommonRuntimeKit.HTTPRequestBase
import class AwsCommonRuntimeKit.Signer
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPRequestBuilder
import enum AwsCommonRuntimeKit.CommonRunTimeError
import enum Smithy.ClientError
import enum SmithyHTTPAuthAPI.AWSSignedBodyHeader
import enum SmithyHTTPAuthAPI.AWSSignedBodyValue
import enum SmithyHTTPAuthAPI.AWSSignatureType
import enum SmithyHTTPAuthAPI.SigningAlgorithm
import enum SmithyHTTPAuthAPI.SigningPropertyKeys
import protocol SmithyIdentity.AWSCredentialIdentityResolver
import protocol SmithyIdentityAPI.Identity
import protocol SmithyHTTPAuthAPI.Signer
import struct AwsCommonRuntimeKit.SigningConfig
import struct ClientRuntime.Date
import struct Smithy.AttributeKey
import struct Smithy.Attributes
import struct Smithy.SwiftLogger
import struct SmithyIdentity.AWSCredentialIdentity
import struct SmithyHTTPAuth.AWSSigningConfig
import struct SmithyHTTPAuthAPI.SigningFlags
import struct Foundation.Date
import struct Foundation.TimeInterval
import struct Foundation.URL
import AWSSDKChecksums

public class AWSSigV4Signer: SmithyHTTPAuthAPI.Signer {

    public init() {}

    public func signRequest<IdentityT: SmithyIdentityAPI.Identity>(
        requestBuilder: SmithyHTTPAPI.HTTPRequestBuilder,
        identity: IdentityT,
        signingProperties: Smithy.Attributes
    ) async throws -> SmithyHTTPAPI.HTTPRequestBuilder {
        guard let isBidirectionalStreamingEnabled = signingProperties.get(
            key: SigningPropertyKeys.bidirectionalStreaming
        ) else {
            throw Smithy.ClientError.authError(
                "Signing properties passed to the AWSSigV4Signer must contain T/F flag for bidirectional streaming."
            )
        }

        guard let identity = identity as? AWSCredentialIdentity else {
            throw Smithy.ClientError.authError(
                "Identity passed to the AWSSigV4Signer must be of type Credentials."
            )
        }

        var signingConfig = try constructSigningConfig(identity: identity, signingProperties: signingProperties)

        // Used to fix signingConfig.date for testing signRequest().
        if let date = signingProperties.get(key: AttributeKey<Date>(name: "SigV4AuthSchemeTests")) {
            signingConfig = fixDateForTests(signingConfig, date)
        }

        let unsignedRequest = requestBuilder.build()
        let crtUnsignedRequest: HTTPRequestBase = isBidirectionalStreamingEnabled ?
            try unsignedRequest.toHttp2Request() :
            try unsignedRequest.toHttpRequest()

        let crtSigningConfig = try signingConfig.toCRTType()

        let crtSignedRequest = try await Signer.signRequest(
            request: crtUnsignedRequest,
            config: crtSigningConfig
        )

        let sdkSignedRequest = requestBuilder.update(from: crtSignedRequest, originalRequest: unsignedRequest)

        if crtSigningConfig.useAwsChunkedEncoding {
            guard let requestSignature = crtSignedRequest.signature else {
                throw Smithy.ClientError.dataNotFound("Could not get request signature!")
            }

            // Set streaming body to an Chunked wrapped type
            try sdkSignedRequest.setChunkedBody(
                signingConfig: crtSigningConfig,
                signature: requestSignature,
                trailingHeaders: unsignedRequest.trailingHeaders,
                checksumString: signingProperties.get(key: SigningPropertyKeys.checksum)
            )
        }

        // Return signed request
        return sdkSignedRequest
    }

    private func constructSigningConfig(
        identity: AWSCredentialIdentity,
        signingProperties: Smithy.Attributes
    ) throws -> AWSSigningConfig {
        guard let unsignedBody = signingProperties.get(key: SigningPropertyKeys.unsignedBody) else {
            throw Smithy.ClientError.authError(
                "Signing properties passed to the AWSSigV4Signer must contain T/F flag for unsigned body."
            )
        }
        guard let signingName = signingProperties.get(key: SigningPropertyKeys.signingName) else {
            throw Smithy.ClientError.authError(
                "Signing properties passed to the AWSSigV4Signer must contain signing name."
            )
        }
        guard let signingRegion = signingProperties.get(key: SigningPropertyKeys.signingRegion) else {
            throw Smithy.ClientError.authError(
                "Signing properties passed to the AWSSigV4Signer must contain signing region."
            )
        }
        guard let signingAlgorithm = signingProperties.get(key: SigningPropertyKeys.signingAlgorithm) else {
            throw Smithy.ClientError.authError(
                "Signing properties passed to the AWSSigV4Signer must contain signing algorithm."
            )
        }

        let expiration: TimeInterval = signingProperties.get(key: SigningPropertyKeys.expiration) ?? 0
        let signedBodyHeader: AWSSignedBodyHeader =
            signingProperties.get(key: SigningPropertyKeys.signedBodyHeader) ?? .none

        // Determine signed body value
        let checksumIsPresent = signingProperties.get(key: SigningPropertyKeys.checksum) != nil
        let isChunkedEligibleStream = signingProperties.get(key: SigningPropertyKeys.isChunkedEligibleStream) ?? false
        let preComputedSha256 = signingProperties.get(key: AttributeKey<String>(name: "SignedBodyValue"))

        let signedBodyValue: AWSSignedBodyValue = determineSignedBodyValue(
            checksumIsPresent: checksumIsPresent,
            isChunkedEligbleStream: isChunkedEligibleStream,
            isUnsignedBody: unsignedBody,
            preComputedSha256: preComputedSha256
        )

        let flags: SigningFlags = SigningFlags(
            useDoubleURIEncode: signingProperties.get(key: SigningPropertyKeys.useDoubleURIEncode) ?? true,
            shouldNormalizeURIPath: signingProperties.get(key: SigningPropertyKeys.shouldNormalizeURIPath) ?? true,
            omitSessionToken: signingProperties.get(key: SigningPropertyKeys.omitSessionToken) ?? false
        )
        let signatureType: AWSSignatureType =
            signingProperties.get(key: SigningPropertyKeys.signatureType) ?? .requestHeaders

        return AWSSigningConfig(
            credentials: identity,
            expiration: expiration,
            signedBodyHeader: signedBodyHeader,
            signedBodyValue: signedBodyValue,
            flags: flags,
            date: Date(),
            service: signingName,
            region: signingRegion,
            signatureType: signatureType,
            signingAlgorithm: signingAlgorithm
        )
    }

    let logger: Smithy.SwiftLogger = SwiftLogger(label: "AWSSigV4Signer")

    public func sigV4SignedURL(
        requestBuilder: SmithyHTTPAPI.HTTPRequestBuilder,
        awsCredentialIdentityResolver: any AWSCredentialIdentityResolver,
        signingName: Swift.String,
        signingRegion: Swift.String,
        date: ClientRuntime.Date,
        expiration: TimeInterval,
        signingAlgorithm: SigningAlgorithm
    ) async -> URL? {
        do {
            let credentials = try await awsCredentialIdentityResolver.getIdentity(
                identityProperties: Attributes()
            )
            let flags = SigningFlags(useDoubleURIEncode: true,
                                     shouldNormalizeURIPath: true,
                                     omitSessionToken: false)
            let signedBodyHeader: AWSSignedBodyHeader = .none
            let signedBodyValue: AWSSignedBodyValue = .empty
            let signingConfig = AWSSigningConfig(
                credentials: credentials,
                expiration: expiration,
                signedBodyHeader: signedBodyHeader,
                signedBodyValue: signedBodyValue,
                flags: flags,
                date: date,
                service: signingName,
                region: signingRegion,
                signatureType: .requestQueryParams,
                signingAlgorithm: signingAlgorithm
            )
            let builtRequest = await sigV4SignedRequest(requestBuilder: requestBuilder, signingConfig: signingConfig)
            guard let presignedURL = builtRequest?.destination.url else {
                logger.error("Failed to generate presigend url")
                return nil
            }
            return presignedURL
        } catch let err {
            logger.error("Failed to generate presigned url: \(err)")
            return nil
        }
    }

    public func sigV4SignedRequest(
        requestBuilder: SmithyHTTPAPI.HTTPRequestBuilder,
        signingConfig: AWSSigningConfig
    ) async -> SmithyHTTPAPI.HTTPRequest? {
        let originalRequest = requestBuilder.build()
        do {
            let crtUnsignedRequest = try originalRequest.toHttpRequest()

            let crtSignedRequest = try await Signer.signRequest(
                request: crtUnsignedRequest,
                config: signingConfig.toCRTType()
            )
            let sdkSignedRequest = requestBuilder.update(from: crtSignedRequest, originalRequest: originalRequest)
            return sdkSignedRequest.build()
        } catch CommonRunTimeError.crtError(let crtError) {
            logger.error("Failed to sign request (CRT): \(crtError)")
            return nil
        } catch let err {
            logger.error("Failed to sign request: \(err)")
            return nil
        }
    }

    private func fixDateForTests(_ signingConfig: AWSSigningConfig, _ fixedDate: Date) -> AWSSigningConfig {
        return AWSSigningConfig(
            credentials: signingConfig.credentials,
            expiration: signingConfig.expiration,
            signedBodyHeader: signingConfig.signedBodyHeader,
            signedBodyValue: signingConfig.signedBodyValue,
            flags: signingConfig.flags,
            date: fixedDate,
            service: signingConfig.service,
            region: signingConfig.region,
            signatureType: signingConfig.signatureType,
            signingAlgorithm: signingConfig.signingAlgorithm
        )
    }

    private func determineSignedBodyValue(
        checksumIsPresent: Bool,
        isChunkedEligbleStream: Bool,
        isUnsignedBody: Bool,
        preComputedSha256: String?
    ) -> AWSSignedBodyValue {
        if !isChunkedEligbleStream {
            // Normal Payloads, Event Streams, etc.
            if isUnsignedBody {
                return .unsignedPayload
            } else if let sha256 = preComputedSha256 {
                return .precomputed(sha256)
            } else {
                return .empty
            }
        }

        // STREAMING-UNSIGNED-PAYLOAD-TRAILER
        if isUnsignedBody { return .streamingUnsignedPayloadTrailer }

        return checksumIsPresent ? .streamingSha256PayloadTrailer : .streamingSha256Payload
    }
}

extension SigningConfig {
    public var useAwsChunkedEncoding: Bool {
        switch self.signedBodyValue {
        case .streamingSha256Payload, .streamingSha256PayloadTrailer, .streamingUnSignedPayloadTrailer:
            return true
        default:
            return false
        }
    }
}
