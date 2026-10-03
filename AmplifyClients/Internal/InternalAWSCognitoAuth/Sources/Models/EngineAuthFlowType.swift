//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation

/// The engine's copy of the plugin's public `AuthFlowType` (`AWSCognitoAuthPlugin/Models/AuthFlowType.swift`).
///
/// It is persisted, inside `SignInMethod.apiBased` and `UserPoolConfigurationData.authFlowType`, so its
/// `Codable` is copied verbatim, quirks included:
/// - `.custom` encodes as `CUSTOM_AUTH_WITH_SRP`, so it decodes back as `.customWithSRP`;
/// - `userAuth(preferredFirstFactor: nil)` writes an explicit `"preferredFirstFactor":null`;
/// - a bare string (the pre-passwordless shape) is decoded through `legacyInit(rawValue:)`.
///
/// Its `==` is copied too, so `.custom` and `.customWithSRP` stay unequal. The only change from the
/// public type is `AuthFactorType` → `EngineAuthFactorType`, and `.custom` is not marked deprecated
/// (the bijection with the public type needs it; the standalone client must not expose it). The plugin
/// converts case to case in `AWSCognitoAuthPlugin/Support/EngineBridge/AuthFlowType+Engine.swift`.
package enum EngineAuthFlowType {

    /// Authentication flow for the Secure Remote Password (SRP) protocol
    case userSRP

    /// Authentication flow for custom flow which are backed by lambda triggers.
    /// Note that `custom`will always begin with a SRP flow.
    case custom

    /// Authentication flow which start with SRP and then move to custom auth flow
    case customWithSRP

    /// Authentication flow which starts without SRP and directly moves to custom auth flow
    case customWithoutSRP

    /// Non-SRP authentication flow; user name and password are passed directly.
    /// If a user migration Lambda trigger is set, this flow will invoke the user migration
    /// Lambda if it doesn't find the user name in the user pool.
    case userPassword

    /// Authentication flow used for user discovering enabled first factors for a user.
    /// - `preferredFirstFactor`: the auth factor type the user should begin signing with if available. If the preferred first factor is not available, the flow would fallback to provide available first factors.
    case userAuth(preferredFirstFactor: EngineAuthFactorType?)

    package init?(rawValue: String) {
        switch rawValue {
        case "CUSTOM_AUTH", "CUSTOM_AUTH_WITH_SRP":
            self = .customWithSRP
        case "CUSTOM_AUTH_WITHOUT_SRP":
            self = .customWithoutSRP
        case "USER_SRP_AUTH":
            self = .userSRP
        case "USER_PASSWORD_AUTH":
            self = .userPassword
        case "USER_AUTH":
            self = .userAuth
        default:
            return nil
        }
    }

    package var rawValue: String {
        switch self {
        case .custom, .customWithSRP:
            return "CUSTOM_AUTH_WITH_SRP"
        case .customWithoutSRP:
            return "CUSTOM_AUTH_WITHOUT_SRP"
        case .userSRP:
            return "USER_SRP_AUTH"
        case .userPassword:
            return "USER_PASSWORD_AUTH"
        case .userAuth:
            return "USER_AUTH"
        }
    }

    // This initializer has been added to migrate credentials that were created in the pre-passwordless era
    package static func legacyInit(rawValue: String) -> Self? {
        switch rawValue {
        case "userSRP":
            return .userSRP
        case "userPassword":
            return .userPassword
        case "custom":
            return .custom
        case "customWithSRP":
            return .customWithSRP
        case "customWithoutSRP":
            return .customWithoutSRP
        default:
            return nil
        }
    }

    package static var userAuth: EngineAuthFlowType {
        return .userAuth(preferredFirstFactor: nil)
    }
}

// MARK: - Equatable Conformance
extension EngineAuthFlowType: Equatable {
    package static func == (lhs: EngineAuthFlowType, rhs: EngineAuthFlowType) -> Bool {
        switch (lhs, rhs) {
        case (.userSRP, .userSRP),
            (.custom, .custom),
            (.customWithSRP, .customWithSRP),
            (.customWithoutSRP, .customWithoutSRP),
            (.userPassword, .userPassword):
            return true
        case (.userAuth(let lhsFactor), .userAuth(let rhsFactor)):
            return lhsFactor == rhsFactor
        default:
            return false
        }
    }
}

// MARK: - Codable Conformance
extension EngineAuthFlowType: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case preferredFirstFactor
    }

    // Encoding the enum
    package func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Encode the type (raw value)
        try container.encode(rawValue, forKey: .type)

        // Handle associated values (for userAuth case)
        switch self {
        case .userAuth(let preferredFirstFactor):
            try container.encode(preferredFirstFactor?.rawValue, forKey: .preferredFirstFactor)
        default:
            break // For other cases, no associated values to encode
        }
    }

    // Decoding the enum
    package init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys>
        do {
            container = try decoder.container(keyedBy: CodingKeys.self)
        } catch DecodingError.typeMismatch {
            // The type mismatch has been added to handle a scenario where the user is migrating passwordless flows.
            // Passwordless flow added a new enum case with a associated type.
            // The association resulted in encoding structure changes that is different from the non-passwordless flows.
            // The structure change causes the type mismatch exception and this code block tries to retrieve the legacy structure and decode it.
            let legacyContainer = try decoder.singleValueContainer()
            let type = try legacyContainer.decode(String.self)
            guard let authFlowType = EngineAuthFlowType.legacyInit(rawValue: type) else {
                throw DecodingError.dataCorruptedError(in: legacyContainer, debugDescription: "Invalid AuthFlowType value")
            }
            self = authFlowType
            return
        } catch {
            throw error
        }

        let type = try container.decode(String.self, forKey: .type)

        // Initialize based on the type
        switch type {
        case "USER_SRP_AUTH":
            self = .userSRP
        case "CUSTOM_AUTH", "CUSTOM_AUTH_WITH_SRP":
            self = .customWithSRP
        case "CUSTOM_AUTH_WITHOUT_SRP":
            self = .customWithoutSRP
        case "USER_PASSWORD_AUTH":
            self = .userPassword
        case "USER_AUTH":
            self = try .userAuth(preferredFirstFactor: Self.decodePreferredFirstFactor(
                from: container,
                logger: decoder.userInfo[.engineLogger] as? any EngineScopedLogger
            ))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid AuthFlowType value")
        }
    }

    /// The `userAuth` case's preferred first factor: `nil` when none was encoded, and a `dataCorrupted` error
    /// for a value that is not an `EngineAuthFactorType`.
    ///
    /// - Parameter logger: the decoder's `CodingUserInfoKey.engineLogger`, which an unsupported factor is logged
    ///   through; without one (the plugin's public decode) it is logged through the global router.
    private static func decodePreferredFirstFactor(
        from container: KeyedDecodingContainer<CodingKeys>,
        logger: (any EngineScopedLogger)?
    ) throws -> EngineAuthFactorType? {
        guard let preferredFirstFactorString = try container.decodeIfPresent(String.self, forKey: .preferredFirstFactor) else {
            return nil
        }
        let parsed = logger.map { EngineAuthFactorType(rawValue: preferredFirstFactorString, logger: $0) }
            ?? EngineAuthFactorType(decodingRawValue: preferredFirstFactorString)
        guard let preferredFirstFactor = parsed else {
            throw DecodingError.dataCorruptedError(
                forKey: .preferredFirstFactor,
                in: container,
                debugDescription: "Unable to decode preferredFirstFactor value"
            )
        }
        return preferredFirstFactor
    }
}

package extension EngineAuthFlowType {

    func getClientFlowType() -> CognitoIdentityProviderClientTypes.AuthFlowType {
        switch self {
        case .custom, .customWithSRP, .customWithoutSRP:
            return .customAuth
        case .userSRP:
            return .userSrpAuth
        case .userPassword:
            return .userPasswordAuth
        case .userAuth:
            return .userAuth
        }
    }
}

extension EngineAuthFlowType: Sendable { }
