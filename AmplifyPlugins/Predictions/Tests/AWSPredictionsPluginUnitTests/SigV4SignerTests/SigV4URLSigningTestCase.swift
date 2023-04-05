//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSPredictionsPlugin

class SigV4URLSigningTestCase: XCTestCase {
    func url() throws -> URL {
        try XCTUnwrap(
            URL(string: "wss://streaming-rekognition.us-east-1.amazon.com/start-face-liveness-session-websocket")
        )
    }

    // example keys source
    // https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys
    let temporaryCredential = SigV4Signer.Credential(
        accessKey: "AKIAIOSFODNN7EXAMPLE",
        secretKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
        sessionToken: "MOCK_SESSION_TOKEN"
    )

    // 20230327T201815Z
    let date = Date(timeIntervalSince1970: 1679948295)

    func testSignWSSURL() throws {
        let url = try url()

        let signer = SigV4Signer(
            credential: temporaryCredential,
            serviceName: "rekognition",
            region: "us-east-1"
        )

        let signedURL = signer.sign(
            url: url,
            method: .get,
            date: { date }
        )

        let components = URLComponents(url: signedURL, resolvingAgainstBaseURL: false)
        let queryItems = try XCTUnwrap(components?.queryItems)

        func queryValue(for key: String, from queryItems: [URLQueryItem]) throws -> String {
            try XCTUnwrap(queryItems.first(where: { $0.name == key })?.value)
        }

        XCTAssertEqual(try queryValue(for: "X-Amz-Date", from: queryItems), "20230327T201815Z")
        XCTAssertEqual(try queryValue(for: "X-Amz-Expires", from: queryItems), "300")
        XCTAssertEqual(try queryValue(for: "X-Amz-Security-Token", from: queryItems), "MOCK_SESSION_TOKEN")
        XCTAssertEqual(try queryValue(for: "X-Amz-Signature", from: queryItems), "575a8f23ab2cd905872c352503fd7714f7813328c12bba0fa41100fc666cc558")
    }

    func testSignURLThenSignPayloadWithPreviousSignature() throws {
        let url = try url()

        let signer = SigV4Signer(
            credential: temporaryCredential,
            serviceName: "rekognition",
            region: "us-east-1"
        )

        _ = signer.sign(
            url: url,
            method: .get,
            date: { date }
        )

        let payload = Data([0, 2, 4, 6])
        let signedPayload = signer.signWithPreviousSignature(
            payload: payload,
            dateHeader: (key: ":date", value: date)
        )

        let expectedBytes: [UInt8] = [
            9, 60, 31, 101,
            190, 66, 33, 11,
            143, 247, 6, 226,
            202, 79, 133, 65,
            157, 4, 205, 21,
            232, 196, 85, 233,
            109, 163, 65, 141,
            26, 240, 205, 218
        ]

        XCTAssertEqual([UInt8](signedPayload), expectedBytes)
    }

    func testSignNoSessionToken() throws {
        let url = try url()

        let credential = SigV4Signer.Credential(
            accessKey: temporaryCredential.accessKey,
            secretKey: temporaryCredential.secretKey,
            sessionToken: nil
        )

        let signer = SigV4Signer(
            credential: credential,
            serviceName: "rekognition",
            region: "us-east-1"
        )

        let signedURL = signer.sign(
            url: url,
            method: .get,
            date: { date }
        )

        let components = URLComponents(url: signedURL, resolvingAgainstBaseURL: false)
        let queryItems = try XCTUnwrap(components?.queryItems)

        func queryValue(for key: String, from queryItems: [URLQueryItem]) throws -> String {
            try XCTUnwrap(queryItems.first(where: { $0.name == key })?.value)
        }

        XCTAssertEqual(try queryValue(for: "X-Amz-Date", from: queryItems), "20230327T201815Z")
        XCTAssertEqual(try queryValue(for: "X-Amz-Expires", from: queryItems), "300")
        XCTAssertNil(queryItems.first(where: { $0.name == "X-Amz-Security-Token" }))
        XCTAssertEqual(try queryValue(for: "X-Amz-Signature", from: queryItems), "9549c81f5557be33fe8649d9c538e1f33d8791800b569a2dfed2a26ab42566ba")
    }

    func testSignWithExpiration() throws {
        let url = try url()

        let credential = SigV4Signer.Credential(
            accessKey: temporaryCredential.accessKey,
            secretKey: temporaryCredential.secretKey,
            sessionToken: nil
        )

        let signer = SigV4Signer(
            credential: credential,
            serviceName: "rekognition",
            region: "us-east-1"
        )

        let expiration = 86_400
        let signedURL = signer.sign(
            url: url,
            method: .get,
            date: { date },
            expires: expiration
        )

        let components = URLComponents(url: signedURL, resolvingAgainstBaseURL: false)
        let queryItems = try XCTUnwrap(components?.queryItems)

        func queryValue(for key: String, from queryItems: [URLQueryItem]) throws -> String {
            try XCTUnwrap(queryItems.first(where: { $0.name == key })?.value)
        }

        XCTAssertEqual(try queryValue(for: "X-Amz-Date", from: queryItems), "20230327T201815Z")
        XCTAssertEqual(try queryValue(for: "X-Amz-Expires", from: queryItems), String(expiration))
        XCTAssertEqual(try queryValue(for: "X-Amz-Signature", from: queryItems), "eb2d084e14a165e42c47d1ad0369b1ea91d31561e6a57d939b071a8f1c3fc18f")
    }
}
