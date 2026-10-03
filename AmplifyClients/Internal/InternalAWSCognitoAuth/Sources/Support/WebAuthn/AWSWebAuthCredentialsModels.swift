//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices
import Foundation
import Smithy

package enum WebAuthnCredentialError<T>: Error {
    case missingValue(_ value: String, type: T.Type)
    case decodingError(_ error: Error, type: T.Type)
}

/// Any `WebAuthnCredentialError`, whatever its `T`: WebAuthn options the engine could not decode, or a
/// ceremony result it could not encode. Lets a caller recognise the generic error as an underlying error
/// (`underlyingError is AnyWebAuthnCredentialError`) without naming each specialisation.
package protocol AnyWebAuthnCredentialError: Error {}

extension WebAuthnCredentialError: AnyWebAuthnCredentialError {}

package struct CredentialAssertionOptions: Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case challengeString = "challenge", relyingPartyId = "rpId"
    }
    private let challengeString: String
    package let relyingPartyId: String

    package init(from string: String?) throws {
        guard let options = string?.data(using: .utf8) else {
            throw WebAuthnCredentialError.missingValue("CredentialOptions", type: Self.self)
        }

        do {
            self = try JSONDecoder().decode(Self.self, from: options)
        } catch {
            throw WebAuthnCredentialError.decodingError(error, type: Self.self)
        }
    }

    package var challenge: Data {
        get throws {
            guard let challenge = challengeString.decodeBase64Url() else {
                throw WebAuthnCredentialError.missingValue("challenge", type: Self.self)
            }
            return challenge
        }
    }

    package var debugDictionary: [String: Any] {
        return [
            "challenge": challengeString.maskedForLog(),
            "relyingPartyId": relyingPartyId
        ]
    }
}

@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
package struct CredentialAssertionPayload: Codable {
    private struct Response: Codable {
        let authenticatorData: String
        let clientDataJSON: String
        let signature: String
        let userHandle: String
    }

    private let id: String
    private let rawId: String
    private let type: String
    private let authenticatorAttachment: String
    private let response: Response

    private init(
        credentialId: String,
        authenticatorData: String,
        clientDataJSON: String,
        signature: String,
        userHandle: String
    ) {
        self.id = credentialId
        self.rawId = credentialId
        self.authenticatorAttachment = "platform"
        self.type = "public-key"
        self.response = Response(
            authenticatorData: authenticatorData,
            clientDataJSON: clientDataJSON,
            signature: signature,
            userHandle: userHandle
        )
    }

    package init(
        from credential: ASAuthorizationPublicKeyCredentialAssertion
    ) throws {
        self.init(
            credentialId: credential.credentialID.toBase64Url(),
            authenticatorData: credential.rawAuthenticatorData.toBase64Url(),
            clientDataJSON: credential.rawClientDataJSON.toBase64Url(),
            signature: credential.signature.toBase64Url(),
            userHandle: credential.userID.toBase64Url()
        )
    }

    package func stringify() throws -> String {
        let data = try JSONEncoder().encode(self)
        return String(decoding: data, as: UTF8.self)
    }
}

package struct CredentialCreationOptions: Sendable {
    package struct User: Sendable {
        package let id: Data
        package let name: String

        fileprivate init(from dictionary: [String: SmithyDocument]) throws {
            guard let idString = try? dictionary["id"]?.asString(),
                  let id = idString.decodeBase64Url() else {
                throw WebAuthnCredentialError.missingValue("user.id", type: Self.self)
            }

            guard let name = try? dictionary["name"]?.asString() else {
                throw WebAuthnCredentialError.missingValue("user.name", type: Self.self)
            }

            self.id = id
            self.name = name
        }
    }

    package struct RelyingParty: Sendable {
        package let id: String

        fileprivate init(from dictionary: [String: SmithyDocument]) throws {
            guard let id = try? dictionary["id"]?.asString() else {
                throw WebAuthnCredentialError.missingValue("rp.id", type: Self.self)
            }
            self.id = id
        }
    }

    package struct Credential: Sendable {
        package let id: Data

        fileprivate init(from dictionary: [String: SmithyDocument]) throws {
            guard let idString = try? dictionary["id"]?.asString(),
                  let id = idString.decodeBase64Url() else {
                throw WebAuthnCredentialError.missingValue("credential.id", type: Self.self)
            }
            self.id = id
        }
    }

    package let challenge: Data
    package let relyingParty: RelyingParty
    package let user: User
    package let excludeCredentials: [Credential]

    package init(from dictionary: [String: SmithyDocument]?) throws {
        guard let challengeString = try? dictionary?["challenge"]?.asString(),
              let challenge = challengeString.decodeBase64Url() else {
            throw WebAuthnCredentialError.missingValue("challenge", type: Self.self)
        }

        guard let relyingParty = try? dictionary?["rp"]?.asStringMap() else {
            throw WebAuthnCredentialError.missingValue("rp", type: Self.self)
        }

        guard let excludeCredentials = try? dictionary?["excludeCredentials"]?.asList() else {
            throw WebAuthnCredentialError.missingValue("excludeCredentials", type: Self.self)
        }

        guard let user = try? dictionary?["user"]?.asStringMap() else {
            throw WebAuthnCredentialError.missingValue("user", type: Self.self)
        }

        self.challenge = challenge
        self.relyingParty = try RelyingParty(from: relyingParty)
        self.user = try User(from: user)
        self.excludeCredentials = try excludeCredentials.map { try Credential(from: $0.asStringMap()) }
    }
}

@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
package struct CredentialRegistrationPayload: Codable {
    private struct Response: Codable {
        let attestationObject: String
        let clientDataJSON: String
        let transports: [String]
    }

    private let id: String
    private let rawId: String
    private let type: String
    private let authenticatorAttachment: String
    private let response: Response

    /// For testing purposes only
    package init(
        credentialId: String,
        attestationObject: String,
        clientDataJSON: String
    ) {
        self.id = credentialId
        self.rawId = credentialId
        self.authenticatorAttachment = "platform"
        self.type = "public-key"
        self.response = Response(
            attestationObject: attestationObject,
            clientDataJSON: clientDataJSON,
            transports: ["internal"]
        )
    }

    package init(
        from credential: ASAuthorizationPublicKeyCredentialRegistration
    ) throws {
        guard let attestationObject = credential.rawAttestationObject?.toBase64Url() else {
            throw WebAuthnCredentialError.missingValue("attestationObject", type: Self.self)
        }

        self.init(
            credentialId: credential.credentialID.toBase64Url(),
            attestationObject: attestationObject,
            clientDataJSON: credential.rawClientDataJSON.toBase64Url()
        )
    }

    package func asData() throws -> Data {
        return try JSONEncoder().encode(self)
    }
}

private extension Data {
    func toBase64Url() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}


private extension String {
    func decodeBase64Url() -> Data? {
        var base64 = replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        if base64.count % 4 != 0 {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }

        return Data(base64Encoded: base64)
    }
}
#endif
