//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider
import Amplify

public enum AuthFlowType {

    /// Authentication flow for the Secure Remote Password (SRP) protocol
    case userSRP

    /// Authentication flow for custom flow which are backed by lambda triggers.
    /// Note that `custom`will always begin with a SRP flow.
    @available(*, deprecated, message: "Use of custom is deprecated, use customWithSrp or customWithoutSrp instead")
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
    case userAuth(preferredFirstFactor: AuthFactorType?)

    var rawValue: String {
        switch self {
        case .custom, .customWithSRP, .customWithoutSRP:
            return "CUSTOM_AUTH"
        case .userSRP:
            return "USER_SRP_AUTH"
        case .userPassword:
            return "USER_PASSWORD_AUTH"
        case .userAuth:
            return "USER_AUTH"
        }
    }

    public static var userAuth: AuthFlowType {
        return .userAuth(preferredFirstFactor: nil)
    }
}

// MARK: - Equatable Conformance
extension AuthFlowType: Equatable {
    public static func ==(lhs: AuthFlowType, rhs: AuthFlowType) -> Bool {
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
extension AuthFlowType: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case preferredFirstFactor
    }

    // Encoding the enum
    public func encode(to encoder: Encoder) throws {
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
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode the type (raw value)
        let type = try container.decode(String.self, forKey: .type)

        // Initialize based on the type
        switch type {
        case "USER_SRP_AUTH":
            self = .userSRP
        case "CUSTOM_AUTH":
            // Depending on your needs, choose either `.custom`, `.customWithSRP`, or `.customWithoutSRP`
            // In this case, we'll default to `.custom`
            self = .custom
        case "USER_PASSWORD_AUTH":
            self = .userPassword
        case "USER_AUTH":
            let preferredFirstFactorString = try container.decode(String.self, forKey: .preferredFirstFactor)
            if let preferredFirstFactor = AuthFactorType(rawValue: preferredFirstFactorString) {
                self = .userAuth(preferredFirstFactor: preferredFirstFactor)
            } else {
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unable to decode preferredFirstFactor value")
            }
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid AuthFlowType value")
        }
    }
}

extension AuthFlowType {

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
