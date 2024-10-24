//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS)
import AuthenticationServices
import Foundation

enum WebAuthnCredentialError<T>: Error {
    case missingValue(_ value: String, type: T.Type)
    case decodingError(_ error: Error, type: T.Type)
}

struct CredentialAssertionOptions: Codable, Equatable {
    private enum CodingKeys : String, CodingKey {
        case challengeString = "challenge", relyingPartyId = "rpId"
    }
    private let challengeString: String
    let relyingPartyId: String

    init(from string: String?) throws {
        guard let options = string?.data(using: .utf8) else {
            throw WebAuthnCredentialError.missingValue("CredentialOptions", type: Self.self)
        }

        do {
            self = try JSONDecoder().decode(Self.self, from: options)
        } catch {
            throw WebAuthnCredentialError.decodingError(error, type: Self.self)
        }
    }

    var challenge: Data {
        get throws {
            guard let challenge = challengeString.decodeBase64Url() else {
                throw WebAuthnCredentialError.missingValue("challenge", type: Self.self)
            }
            return challenge
        }
    }

    var debugDictionary: [String: Any] {
        return [
            "challenge": challengeString.masked(),
            "relyingPartyId": relyingPartyId
        ]
    }
}

@available(iOS 17.4, macOS 13.5, *)
struct CredentialAssertionPayload: Codable {
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
        id = credentialId
        rawId = credentialId
        authenticatorAttachment = "platform"
        type = "public-key"
        response = Response(
            authenticatorData: authenticatorData,
            clientDataJSON: clientDataJSON,
            signature: signature,
            userHandle: userHandle
        )
    }

    init(
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

    func stringify() throws -> String {
        let data = try JSONEncoder().encode(self)
        return String(decoding: data, as: UTF8.self)
    }
}

struct CredentialCreationOptions: Codable {
    private enum CodingKeys : String, CodingKey {
        case challengeString = "challenge", relyingParty = "rp", user, excludeCredentials
    }

    struct User: Codable {
        private enum CodingKeys : String, CodingKey {
            case idString = "id", name
        }

        private let idString: String
        let name: String

        var id: Data {
            get throws {
                guard let id = idString.decodeBase64Url() else {
                    throw WebAuthnCredentialError.missingValue("user.id", type: Self.self)
                }
                return id
            }
        }
    }

    struct RelyingParty: Codable {
        let id: String
    }

    struct Credential: Codable {
        private enum CodingKeys : String, CodingKey {
            case idString = "id"
        }

        private let idString: String

        var id: Data {
            get throws {
                guard let id = idString.decodeBase64Url() else {
                    throw WebAuthnCredentialError.missingValue("credential.id", type: Self.self)
                }
                return id
            }
        }
    }

    private let challengeString: String
    let relyingParty: RelyingParty
    let user: User
    let excludeCredentials: [Credential]

    init(from string: String?) throws {
        guard let options = string?.data(using: .utf8) else {
            throw WebAuthnCredentialError.missingValue("CredentialOptions", type: Self.self)
        }

        do {
            self = try JSONDecoder().decode(Self.self, from: options)
        } catch {
            throw WebAuthnCredentialError.decodingError(error, type: Self.self)
        }
    }

    var challenge: Data {
        get throws {
            guard let challenge = challengeString.decodeBase64Url() else {
                throw WebAuthnCredentialError.missingValue("challenge", type: Self.self)
            }
            return challenge
        }
    }
}

@available(iOS 17.4, macOS 13.5, *)
struct CredentialRegistrationPayload: Codable {
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

    private init(
        credentialId: String,
        attestationObject: String,
        clientDataJSON: String
    ) {
        id = credentialId
        rawId = credentialId
        authenticatorAttachment = "platform"
        type = "public-key"
        response = Response(
            attestationObject: attestationObject,
            clientDataJSON: clientDataJSON,
            transports: ["internal"]
        )
    }

    init(
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

    func stringify() throws -> String {
        let data = try JSONEncoder().encode(self)
        return String(decoding: data, as: UTF8.self)
    }
}

private extension Data {
    func toBase64Url() -> String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}


private extension String {
    func decodeBase64Url() -> Data? {
        var base64 = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        if base64.count % 4 != 0 {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }

        return Data(base64Encoded: base64)
    }
}
#endif
