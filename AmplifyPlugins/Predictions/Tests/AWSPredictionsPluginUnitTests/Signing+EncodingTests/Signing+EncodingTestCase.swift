//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSPredictionsPlugin

final class SigningEncodingTestCase: XCTestCase {
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

    /// Given: A payload and credentials.
    /// When: A SigV4 signed url is created with credentials,
    ///  the payload is Event Stream Encoded,
    ///  the encoded payload is signed,
    ///  the encoded payload is then encoded again using the
    ///  signature in `:chunk-signature` header
    /// Then: Each encoded intermediary step should contain
    ///  the expected bytes (idompotent)
    func testEncodeSignEncode() throws {
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

        let payload = Data([2, 4, 6, 8])

        let encodedPayload = EventStream.Encoder().encode(
            payload: payload,
            headers: [:]
        )
        let expectedEncodedPayloadBytes: [UInt8] = [
            0, 0, 0, 20, 0, 0, 0, 0,
            240, 66, 238, 43, 2, 4, 6, 8,
            219, 36, 220, 7
        ]
        XCTAssertEqual([UInt8](encodedPayload), expectedEncodedPayloadBytes)

        let signedPayload = signer.signWithPreviousSignature(
            payload: encodedPayload,
            dateHeader: (key: ":date", value: date)
        )
        let expectedSignedPayloadBytes: [UInt8] = [
            186, 67, 89, 20, 201, 59, 213, 115,
            115, 133, 5, 119, 180, 239, 196, 111,
            150, 149, 208, 82, 89, 106, 246, 177,
            30, 244, 109, 103, 44, 45, 20, 113
        ]
        XCTAssertEqual([UInt8](signedPayload), expectedSignedPayloadBytes)

        let encodedEvent = EventStream.Encoder().encode(
            payload: encodedPayload,
            headers: [":chunk-signature": .data(signedPayload)]

        )
        let expectedEncodedEventBytes: [UInt8] = [
            0, 0, 0, 88, 0, 0, 0, 52,
            76, 245, 175, 214, 16, 58, 99, 104,
            117, 110, 107, 45, 115, 105, 103, 110,
            97, 116, 117, 114, 101, 6, 0, 32,
            186, 67, 89, 20, 201, 59, 213, 115, 115,
            133, 5, 119, 180, 239, 196, 111, 150,
            149, 208, 82, 89, 106, 246, 177, 30,
            244, 109, 103, 44, 45, 20, 113, 0, 0,
            0, 20, 0, 0, 0, 0, 240, 66,
            238, 43, 2, 4, 6, 8, 219, 36,
            220, 7, 153, 41, 16, 121
        ]
        XCTAssertEqual([UInt8](encodedEvent), expectedEncodedEventBytes)
    }

    /// Given: A payload and credentials.
    /// When: A SigV4 signed url is created with credentials,
    ///  the payload is Event Stream Encoded,
    ///  the encoded payload is signed,
    ///  the encoded payload is then encoded again into the encodedEvent
    ///  using the signature in `:chunk-signature` header,
    ///  the encoded event is then decoded in the decodedEvent
    /// Then: The decodedEvent should contain a `:chunk-signature` header
    ///  where the value matches the signature generated in the prior steps.
    func testEncodeSignEncodeDecode() throws {
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

        let payload = Data([2, 4, 6, 8])

        let encodedPayload = EventStream.Encoder().encode(
            payload: payload,
            headers: [:]
        )

        let signedPayload = signer.signWithPreviousSignature(
            payload: encodedPayload,
            dateHeader: (key: ":date", value: date)
        )

        let encodedEvent = EventStream.Encoder().encode(
            payload: encodedPayload,
            headers: [":chunk-signature": .data(signedPayload)]
        )

        let decodedEvent = try EventStream.Decoder().decode(data: encodedEvent)
        let decodedSignatureHeader = try XCTUnwrap(
            decodedEvent.headers.first(where: { $0.name == ":chunk-signature" })
        ).value

        XCTAssertEqual(decodedSignatureHeader, String(decoding: signedPayload, as: UTF8.self))
    }
}
