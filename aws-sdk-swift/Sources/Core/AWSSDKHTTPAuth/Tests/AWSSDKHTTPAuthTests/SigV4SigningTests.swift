//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import XCTest
import SmithyHTTPAuthAPI
import SmithyHTTPAuth
import SmithyHTTPAPI
import SmithyIdentity
import SmithyTestUtil
import AwsCommonRuntimeKit
@_spi(SmithyTimestamps) import SmithyTimestamps
import SmithyEventStreams
import SmithyEventStreamsAPI
import AWSSDKIdentity
import AWSSDKHTTPAuth

class Sigv4SigningTests: XCTestCase {
    override func setUp() {
        CommonRuntimeKit.initialize()
    }

    // Test success case
    func testSignRequestSuccess() async throws {
        let dateString = "2024-01-16T12:36:00Z"
        let date = try XCTUnwrap(TimestampFormatter(format: .dateTime).date(from: dateString))

        let requestBuilder = HTTPRequestBuilder()
            .withHost("example.amazonaws.com")
            .withPath("/")
            .withMethod(.get)
            .withPort(443)
            .withProtocol(.http)
            .withHeader(name: "host", value: "example.amazonaws.com")

        let credentials = AWSCredentialIdentity(accessKey: "test-access-key", secret: "test-secret-key")

        var signingProperties = Attributes()
        signingProperties.set(key: SigningPropertyKeys.bidirectionalStreaming, value: false)
        signingProperties.set(key: SigningPropertyKeys.unsignedBody, value: false)
        signingProperties.set(key: SigningPropertyKeys.signingName, value: "test")
        signingProperties.set(key: SigningPropertyKeys.signingRegion, value: "us-east-1")
        signingProperties.set(key: SigningPropertyKeys.signingAlgorithm, value: .sigv4)
        signingProperties.set(key: AttributeKey<Date>(name: "SigV4AuthSchemeTests"), value: date)

        let signedRequest = try await AWSSigV4Signer().signRequest(
            requestBuilder: requestBuilder,
            identity: credentials,
            signingProperties: signingProperties
        )

        let expectedSignature = "68a60ecd39081e56bc2413c3397669c72ba61642c5d283aa15ad2f7e155c3e04"
        XCTAssertEqual(expectedSignature, signedRequest.signature)
    }

    // Test exception cases
    func testSignRequestMissingBidirectionalStreamingFlag() async throws {
        let dateString = "2024-01-16T12:36:00Z"
        let date = try XCTUnwrap(TimestampFormatter(format: .dateTime).date(from: dateString))

        let requestBuilder = HTTPRequestBuilder()
            .withHost("example.amazonaws.com")
            .withPath("/")
            .withMethod(.get)
            .withPort(443)
            .withProtocol(.http)
            .withHeader(name: "host", value: "example.amazonaws.com")

        let credentials = AWSCredentialIdentity(accessKey: "test-access-key", secret: "test-secret-key")

        var signingProperties = Attributes()
        signingProperties.set(key: SigningPropertyKeys.unsignedBody, value: false)
        signingProperties.set(key: SigningPropertyKeys.signingName, value: "test")
        signingProperties.set(key: SigningPropertyKeys.signingRegion, value: "us-east-1")
        signingProperties.set(key: SigningPropertyKeys.signingAlgorithm, value: .sigv4)
        signingProperties.set(key: AttributeKey<Date>(name: "SigV4AuthSchemeTests"), value: date)

        do {
            _ = try await AWSSigV4Signer().signRequest(
                requestBuilder: requestBuilder,
                identity: credentials,
                signingProperties: signingProperties
            )
            XCTFail("The code failed to throw at expected point.")
        } catch ClientError.authError(let message) {
            let expectedMessage = "Signing properties passed to the AWSSigV4Signer must contain T/F flag for bidirectional streaming."
            XCTAssertEqual(expectedMessage, message)
        } catch {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
        }
    }

    func testSignRequestWrongTypeOfIdentity() async throws {
        let dateString = "2024-01-16T12:36:00Z"
        let date = try XCTUnwrap(TimestampFormatter(format: .dateTime).date(from: dateString))

        let requestBuilder = HTTPRequestBuilder()
            .withHost("example.amazonaws.com")
            .withPath("/")
            .withMethod(.get)
            .withPort(443)
            .withProtocol(.http)
            .withHeader(name: "host", value: "example.amazonaws.com")

        let credentials = MockIdentity()

        var signingProperties = Attributes()
        signingProperties.set(key: SigningPropertyKeys.bidirectionalStreaming, value: false)
        signingProperties.set(key: SigningPropertyKeys.unsignedBody, value: false)
        signingProperties.set(key: SigningPropertyKeys.signingName, value: "test")
        signingProperties.set(key: SigningPropertyKeys.signingRegion, value: "us-east-1")
        signingProperties.set(key: SigningPropertyKeys.signingAlgorithm, value: .sigv4)
        signingProperties.set(key: AttributeKey<Date>(name: "SigV4AuthSchemeTests"), value: date)

        do {
            _ = try await AWSSigV4Signer().signRequest(
                requestBuilder: requestBuilder,
                identity: credentials,
                signingProperties: signingProperties
            )
            XCTFail("The code failed to throw at expected point.")
        } catch ClientError.authError(let message) {
            let expectedMessage = "Identity passed to the AWSSigV4Signer must be of type Credentials."
            XCTAssertEqual(expectedMessage, message)
        } catch {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
        }
    }

    func testSignRequestMissingUnsignedBodyFlag() async throws {
        let dateString = "2024-01-16T12:36:00Z"
        let date = try XCTUnwrap(TimestampFormatter(format: .dateTime).date(from: dateString))

        let requestBuilder = HTTPRequestBuilder()
            .withHost("example.amazonaws.com")
            .withPath("/")
            .withMethod(.get)
            .withPort(443)
            .withProtocol(.http)
            .withHeader(name: "host", value: "example.amazonaws.com")

        let credentials = AWSCredentialIdentity(accessKey: "test-access-key", secret: "test-secret-key")

        var signingProperties = Attributes()
        signingProperties.set(key: SigningPropertyKeys.bidirectionalStreaming, value: false)
        signingProperties.set(key: SigningPropertyKeys.signingName, value: "test")
        signingProperties.set(key: SigningPropertyKeys.signingRegion, value: "us-east-1")
        signingProperties.set(key: SigningPropertyKeys.signingAlgorithm, value: .sigv4)
        signingProperties.set(key: AttributeKey<Date>(name: "SigV4AuthSchemeTests"), value: date)

        do {
            _ = try await AWSSigV4Signer().signRequest(
                requestBuilder: requestBuilder,
                identity: credentials,
                signingProperties: signingProperties
            )
            XCTFail("The code failed to throw at expected point.")
        } catch ClientError.authError(let message) {
            let expectedMessage = "Signing properties passed to the AWSSigV4Signer must contain T/F flag for unsigned body."
            XCTAssertEqual(expectedMessage, message)
        } catch {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
        }
    }

    func testSignRequestMissingSigningName() async throws {
        let dateString = "2024-01-16T12:36:00Z"
        let date = try XCTUnwrap(TimestampFormatter(format: .dateTime).date(from: dateString))

        let requestBuilder = HTTPRequestBuilder()
            .withHost("example.amazonaws.com")
            .withPath("/")
            .withMethod(.get)
            .withPort(443)
            .withProtocol(.http)
            .withHeader(name: "host", value: "example.amazonaws.com")

        let credentials = AWSCredentialIdentity(accessKey: "test-access-key", secret: "test-secret-key")

        var signingProperties = Attributes()
        signingProperties.set(key: SigningPropertyKeys.bidirectionalStreaming, value: false)
        signingProperties.set(key: SigningPropertyKeys.unsignedBody, value: false)
        signingProperties.set(key: SigningPropertyKeys.signingRegion, value: "us-east-1")
        signingProperties.set(key: SigningPropertyKeys.signingAlgorithm, value: .sigv4)
        signingProperties.set(key: AttributeKey<Date>(name: "SigV4AuthSchemeTests"), value: date)

        do {
            _ = try await AWSSigV4Signer().signRequest(
                requestBuilder: requestBuilder,
                identity: credentials,
                signingProperties: signingProperties
            )
            XCTFail("The code failed to throw at expected point.")
        } catch ClientError.authError(let message) {
            let expectedMessage = "Signing properties passed to the AWSSigV4Signer must contain signing name."
            XCTAssertEqual(expectedMessage, message)
        } catch {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
        }
    }

    func testSignRequestMissingSigningRegion() async throws {
        let dateString = "2024-01-16T12:36:00Z"
        let date = try XCTUnwrap(TimestampFormatter(format: .dateTime).date(from: dateString))

        let requestBuilder = HTTPRequestBuilder()
            .withHost("example.amazonaws.com")
            .withPath("/")
            .withMethod(.get)
            .withPort(443)
            .withProtocol(.http)
            .withHeader(name: "host", value: "example.amazonaws.com")

        let credentials = AWSCredentialIdentity(accessKey: "test-access-key", secret: "test-secret-key")

        var signingProperties = Attributes()
        signingProperties.set(key: SigningPropertyKeys.bidirectionalStreaming, value: false)
        signingProperties.set(key: SigningPropertyKeys.unsignedBody, value: false)
        signingProperties.set(key: SigningPropertyKeys.signingName, value: "test")
        signingProperties.set(key: SigningPropertyKeys.signingAlgorithm, value: .sigv4)
        signingProperties.set(key: AttributeKey<Date>(name: "SigV4AuthSchemeTests"), value: date)

        do {
            _ = try await AWSSigV4Signer().signRequest(
                requestBuilder: requestBuilder,
                identity: credentials,
                signingProperties: signingProperties
            )
            XCTFail("The code failed to throw at expected point.")
        } catch ClientError.authError(let message) {
            let expectedMessage = "Signing properties passed to the AWSSigV4Signer must contain signing region."
            XCTAssertEqual(expectedMessage, message)
        } catch {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
        }
    }

    func testSignRequestMissingSigningAlgorithm() async throws {
        let dateString = "2024-01-16T12:36:00Z"
        let date = try XCTUnwrap(TimestampFormatter(format: .dateTime).date(from: dateString))

        let requestBuilder = HTTPRequestBuilder()
            .withHost("example.amazonaws.com")
            .withPath("/")
            .withMethod(.get)
            .withPort(443)
            .withProtocol(.http)
            .withHeader(name: "host", value: "example.amazonaws.com")

        let credentials = AWSCredentialIdentity(accessKey: "test-access-key", secret: "test-secret-key")

        var signingProperties = Attributes()
        signingProperties.set(key: SigningPropertyKeys.bidirectionalStreaming, value: false)
        signingProperties.set(key: SigningPropertyKeys.unsignedBody, value: false)
        signingProperties.set(key: SigningPropertyKeys.signingName, value: "test")
        signingProperties.set(key: SigningPropertyKeys.signingRegion, value: "us-east-1")
        signingProperties.set(key: AttributeKey<Date>(name: "SigV4AuthSchemeTests"), value: date)

        do {
            _ = try await AWSSigV4Signer().signRequest(
                requestBuilder: requestBuilder,
                identity: credentials,
                signingProperties: signingProperties
            )
            XCTFail("The code failed to throw at expected point.")
        } catch ClientError.authError(let message) {
            let expectedMessage = "Signing properties passed to the AWSSigV4Signer must contain signing algorithm."
            XCTAssertEqual(expectedMessage, message)
        } catch {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
        }
    }

    func testPresigner() async throws {
        let dateString = "2015-08-30T12:36:00Z"
        let date = try XCTUnwrap(TimestampFormatter(format: .dateTime).date(from: dateString))

        let requestBuilder = HTTPRequestBuilder()
            .withHost("example.amazonaws.com")
            .withPath("")
            .withMethod(.get)
            .withPort(443)
            .withProtocol(.http)
            .withHeader(name: "host", value: "example.amazonaws.com")
            .withQueryItem(URIQueryItem(name: "%E1%88%B4", value: "bar"))

        guard let url = await AWSSigV4Signer().sigV4SignedURL(requestBuilder: requestBuilder,
                                                            awsCredentialIdentityResolver: TestCustomAWSCredentialIdentityResolver(),
                                                            signingName: "service",
                                                            signingRegion: "us-east-1",
                                                            date: date,
                                                            expiration: 86400,
                                                            signingAlgorithm: .sigv4) else {
            XCTFail("Unable to generate URL")
            return
        }
        XCTAssertEqual("http://example.amazonaws.com:443?%E1%88%B4=bar&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIDEXAMPLE%2F20150830%2Fus-east-1%2Fservice%2Faws4_request&X-Amz-Date=20150830T123600Z&X-Amz-SignedHeaders=host&X-Amz-Expires=86400&X-Amz-Signature=32dea9080047b41e56ee852fe3eba49dae1911b9c5e5728cc1691704f168c70f", url.absoluteString)
    }
}

class TestCustomAWSCredentialIdentityResolver: AWSCredentialIdentityResolver {
    let credentials: AWSCredentialIdentity
    
    init(credentials: AWSCredentialIdentity) {
        self.credentials = credentials
    }
    
    convenience init() {
        self.init(credentials: AWSCredentialIdentity(
            accessKey: "AKIDEXAMPLE",
            secret: "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY",
            expiration: .init(timeIntervalSinceNow: 30)
        ))
    }
    
    func getIdentity(identityProperties: Attributes?) async throws -> AWSCredentialIdentity {
        return AWSCredentialIdentity(
            accessKey: "AKIDEXAMPLE",
            secret: "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY",
            expiration: .init(timeIntervalSinceNow: 30)
        )
    }
}
