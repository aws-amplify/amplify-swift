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
import SmithyTimestamps
import SmithyEventStreams
import SmithyEventStreamsAPI
import AWSSDKIdentity
import AWSSDKHTTPAuth

class SigV4EventSigningTests: XCTestCase {

    override func setUp() {
        CommonRuntimeKit.initialize()
    }

    func testSignEvent() async {
        let credentials = AWSCredentialIdentity(accessKey: "fake access key", secret: "fake secret key")

        let encoder = SmithyEventStreams.DefaultMessageEncoder()

        let message = Message(
            headers: [
                .init(name: "some-header", value: .string("value")),
            ],
            payload: "test payload".data(using: .utf8)!
        )

        // create Date with fractional seconds
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let epoch = formatter.date(from: "1973-11-29T21:33:09.000001234Z")!

        let staticAWSCredentialIdentityResolver = try! StaticAWSCredentialIdentityResolver(
            credentials
        )

        let context = ContextBuilder()
            .withSigningName(value: "testservice")
            .withRegion(value: "us-east-1")
            .withIdentityResolver(
                value: staticAWSCredentialIdentityResolver,
                schemeID: "aws.auth#sigv4"
            )
            .withIdentityResolver(
                value: staticAWSCredentialIdentityResolver,
                schemeID: "aws.auth#sigv4a"
            )
            .build()

        let signingConfig = try! await context.makeEventStreamSigningConfig(date: epoch.withoutFractionalSeconds())

        let prevSignature = try! "last message sts".data(using: .utf8)!.computeSHA256().encodeToHexString()

        let messagePayload = try! encoder.encode(message: message)

        let result = try! await AWSSigV4Signer().signEvent(payload: messagePayload,
                                                         previousSignature: prevSignature,
                                                         signingConfig: signingConfig)
        XCTAssertEqual(":date", result.output.headers[0].name)

        guard case let .timestamp(dateHeaderValue) = result.output.headers[0].value else {
            XCTFail()
            return
        }

        XCTAssertEqual(epoch.timeIntervalSince1970, dateHeaderValue.timeIntervalSince1970)

        XCTAssertEqual(":chunk-signature", result.output.headers[1].name)
        print(result.signature)
        guard case let .byteArray(actualSignatureBuffer) = result.output.headers[1].value else {
            XCTFail()
            return
        }
        let actualSignature = actualSignatureBuffer.encodeToHexString()
        XCTAssertEqual(result.signature, actualSignature)

        let expected = "1ea04a4f6becd85ae3e38e379ffaf4bb95042603f209512476cc6416868b31ee"
        XCTAssertEqual(expected, actualSignature)
    }
}
