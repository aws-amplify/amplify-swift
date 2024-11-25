//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

class PreferredChallengeHelper {

    let authFactor: AuthFactorType
    let password: String?
    let username: String
    let environment: Environment
    private(set) var srpStateData: SRPStateData? = nil

    init(authFactor: AuthFactorType,
         password: String?,
         username: String,
         environment: Environment) {
        self.authFactor = authFactor
        self.password = password
        self.username = username
        self.environment = environment
    }

    func toCognitoAuthParameters() throws -> [String: String] {
        var authParameters: [String: String] = [:]
        authParameters["PREFERRED_CHALLENGE"] = authFactor.challengeResponse

        switch authFactor {
        case .password:
            guard let password = password else {
                throw AuthError.validation(
                    AuthPluginErrorConstants.signInPasswordError.field,
                    AuthPluginErrorConstants.signInPasswordError.errorDescription,
                    AuthPluginErrorConstants.signInPasswordError.recoverySuggestion)
            }
            authParameters["PASSWORD"] = password
        case .passwordSRP:
            let srpStateData = try generateSRPStateData()
            authParameters["SRP_A"] = srpStateData.srpKeyPair.publicKeyHexValue
        default:
            break
        }
        return authParameters
    }

    private func generateSRPStateData() throws -> SRPStateData {
        let srpEnv = try environment.srpEnvironment()
        let nHexValue = srpEnv.srpConfiguration.nHexValue
        let gHexValue = srpEnv.srpConfiguration.gHexValue

        let srpClient = try SRPSignInHelper.srpClient(srpEnv)
        let srpKeyPair = srpClient.generateClientKeyPair()
        guard let password = password else {
            throw AuthError.validation(
                AuthPluginErrorConstants.signInPasswordError.field,
                AuthPluginErrorConstants.signInPasswordError.errorDescription,
                AuthPluginErrorConstants.signInPasswordError.recoverySuggestion)
        }
        let srpStateData = SRPStateData(
            username: username,
            password: password,
            NHexValue: nHexValue,
            gHexValue: gHexValue,
            srpKeyPair: srpKeyPair,
            clientTimestamp: Date())
        self.srpStateData = srpStateData
        return srpStateData
    }
}
