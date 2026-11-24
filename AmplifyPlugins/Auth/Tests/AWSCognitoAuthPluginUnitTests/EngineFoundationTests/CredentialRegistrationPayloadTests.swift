//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices
import XCTest
import InternalAWSCognitoAuth

/// The `RegistrationResponseJSON` the engine sends to `CompleteWebAuthnRegistration`, which Cognito stores and
/// returns as the credential's `allowCredentials` entry at sign-in.
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
final class CredentialRegistrationPayloadTests: XCTestCase {

    /// A platform passkey reports the hybrid and internal transports
    ///
    /// - Given: a registration payload with the default, platform, attachment
    /// - When:
    ///    - it is encoded with `asData()`
    /// - Then:
    ///    - the JSON has exactly `id`, `rawId`, `type`, `authenticatorAttachment` and `response`, and `response` exactly
    ///      `attestationObject`, `clientDataJSON` and `transports`
    ///    - `authenticatorAttachment` is `platform`, and `transports` is `["hybrid", "internal"]`, sorted as
    ///      `getTransports()` returns them
    ///
    func testAsData_withPlatformAttachment_reportsHybridAndInternalTransports() throws {
        let json = try Self.json(of: CredentialRegistrationPayload(
            credentialId: "Y3JlZA",
            attestationObject: "YXR0",
            clientDataJSON: "Y2xpZW50"
        ))

        XCTAssertEqual(Set(json.keys), ["id", "rawId", "type", "authenticatorAttachment", "response"])
        XCTAssertEqual(json["id"] as? String, "Y3JlZA")
        XCTAssertEqual(json["rawId"] as? String, "Y3JlZA")
        XCTAssertEqual(json["type"] as? String, "public-key")
        XCTAssertEqual(json["authenticatorAttachment"] as? String, "platform")
        let response = try XCTUnwrap(json["response"] as? [String: Any])
        XCTAssertEqual(Set(response.keys), ["attestationObject", "clientDataJSON", "transports"])
        XCTAssertEqual(response["attestationObject"] as? String, "YXR0")
        XCTAssertEqual(response["clientDataJSON"] as? String, "Y2xpZW50")
        XCTAssertEqual(response["transports"] as? [String], ["hybrid", "internal"])
    }

    /// A passkey created on another device reports the cross-platform attachment
    ///
    /// - Given: a registration payload with the cross-platform attachment, as when the user saves the passkey on a
    ///   phone over hybrid
    /// - When:
    ///    - it is encoded with `asData()`
    /// - Then:
    ///    - `authenticatorAttachment` is `cross-platform`, and `transports` is still `["hybrid", "internal"]`
    ///
    func testAsData_withCrossPlatformAttachment_reportsCrossPlatform() throws {
        let json = try Self.json(of: CredentialRegistrationPayload(
            credentialId: "Y3JlZA",
            attestationObject: "YXR0",
            clientDataJSON: "Y2xpZW50",
            attachment: .crossPlatform
        ))

        XCTAssertEqual(json["authenticatorAttachment"] as? String, "cross-platform")
        let response = try XCTUnwrap(json["response"] as? [String: Any])
        XCTAssertEqual(response["transports"] as? [String], ["hybrid", "internal"])
    }

    /// A registration that is not the platform provider's keeps the platform values
    ///
    /// - Given: a registration that is not an `ASAuthorizationPlatformPublicKeyCredentialRegistration`, so has no
    ///   attachment
    /// - When:
    ///    - a payload is made from it and encoded
    /// - Then:
    ///    - its data is base64url-encoded, `authenticatorAttachment` is `platform`, and `transports` is
    ///      `["hybrid", "internal"]`
    ///
    func testInitFromRegistration_withNonPlatformRegistration_keepsThePlatformValues() throws {
        let json = try Self.json(of: CredentialRegistrationPayload(
            from: FakeRegistration(attestationObject: Data("att".utf8))
        ))

        XCTAssertEqual(json["id"] as? String, "Y3JlZA")
        XCTAssertEqual(json["rawId"] as? String, "Y3JlZA")
        XCTAssertEqual(json["authenticatorAttachment"] as? String, "platform")
        let response = try XCTUnwrap(json["response"] as? [String: Any])
        XCTAssertEqual(response["attestationObject"] as? String, "YXR0")
        XCTAssertEqual(response["clientDataJSON"] as? String, "Y2xpZW50")
        XCTAssertEqual(response["transports"] as? [String], ["hybrid", "internal"])
    }

    /// A registration without an attestation object
    ///
    /// - Given: a registration whose `rawAttestationObject` is `nil`
    /// - When:
    ///    - a payload is made from it
    /// - Then:
    ///    - it throws `WebAuthnCredentialError.missingValue("attestationObject", …)`
    ///
    func testInitFromRegistration_withoutAttestationObject_throwsMissingValue() {
        XCTAssertThrowsError(try CredentialRegistrationPayload(from: FakeRegistration(attestationObject: nil))) { error in
            guard case .missingValue(let value, _)? = error as? WebAuthnCredentialError<CredentialRegistrationPayload> else {
                return XCTFail("Expected missingValue, got \(error)")
            }
            XCTAssertEqual(value, "attestationObject")
        }
    }

    private static func json(of payload: CredentialRegistrationPayload) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: payload.asData()) as? [String: Any])
    }
}

/// A registration the test can make: the platform's own has no public initializer.
@objc(CredentialRegistrationPayloadTestsFakeRegistration)
private final class FakeRegistration: NSObject, ASAuthorizationPublicKeyCredentialRegistration {
    static var supportsSecureCoding: Bool { true }
    let rawAttestationObject: Data?
    let rawClientDataJSON = Data("client".utf8)
    let credentialID = Data("cred".utf8)

    init(attestationObject: Data?) {
        self.rawAttestationObject = attestationObject
    }

    required init?(coder: NSCoder) { nil }
    func encode(with coder: NSCoder) {}
    func copy(with zone: NSZone? = nil) -> Any { self }
}
#endif
