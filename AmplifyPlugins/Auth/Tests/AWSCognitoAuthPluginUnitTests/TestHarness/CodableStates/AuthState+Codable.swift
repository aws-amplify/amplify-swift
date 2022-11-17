//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin
import Foundation

extension AuthState: Codable {

    enum CodingKeys: String, CodingKey {
        case type
        case authenticationState = "AuthenticationState"
        case authorizationState = "AuthorizationState"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let type = try values.decode(String.self, forKey: .type)

        if type == "AuthState.Configured" {
            let authenticationState = try values.decode(AuthenticationState.self, forKey: .authenticationState)
            let authorizationState = try values.decode(AuthorizationState.self, forKey: .authorizationState)
            self = .configured(
                authenticationState,
                authorizationState)
        } else {
            fatalError("Decoding not supported")
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .configured(let authenticationState, let authorizationState):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(authenticationState, forKey: .authenticationState)
            try container.encode(authorizationState, forKey: .authorizationState)
        default:
            fatalError("not implemented")
        }

    }

    static func initialize(
        fileName: String,
        with fileExtension: String = "") -> AuthState {
            let bundle = Bundle.authCognitoTestBundle()
            let url = bundle.url(
                forResource: fileName,
                withExtension: fileExtension,
                subdirectory: AuthTestHarnessConstants.authStatesResourcePath)!
            let fileData: Data = try! Data(contentsOf: url)
            return try! JSONDecoder().decode(
                AuthState.self, from: fileData)
        }
}
