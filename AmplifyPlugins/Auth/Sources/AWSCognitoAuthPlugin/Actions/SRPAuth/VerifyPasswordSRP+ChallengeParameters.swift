//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension VerifyPasswordSRP {
    func challengeParameters() throws -> [String: String] {
        guard let parameters = authResponse.challengeParameters else {
            let message = "ChallengeParameters is empty from service"
            throw SignInError.invalidServiceResponse(message: message)
        }
        return parameters
    }

    func saltHex(_ parameters: [String: String]) throws -> String {
        guard let saltHex = parameters["SALT"], !saltHex.isEmpty else {
            let message = "Salt is empty from service"
            throw SignInError.invalidServiceResponse(message: message)
        }
        return saltHex
    }

    func secretBlockString(_ parameters: [String: String])
    throws -> String {
        guard let secretBlockString = parameters["SECRET_BLOCK"]
        else {
            let message = "Secret block is empty from service"
            throw SignInError.invalidServiceResponse(message: message)
        }
        return secretBlockString
    }

    func secretBlock(_ secretBlockString: String) throws -> Data {
        guard let serverSecretBlock = Data(base64Encoded: secretBlockString)
        else {
            let message = "Could not convert secret block to Data"
            throw SignInError.invalidServiceResponse(message: message)
        }
        return serverSecretBlock
    }

    func serverPublic(_ parameters: [String: String]) throws -> String {
        guard let serverPublicBHexString = parameters["SRP_B"] else {
            let message = "SRP_B not found from the service response"
            throw SignInError.invalidServiceResponse(message: message)
        }
        return serverPublicBHexString
    }
}
