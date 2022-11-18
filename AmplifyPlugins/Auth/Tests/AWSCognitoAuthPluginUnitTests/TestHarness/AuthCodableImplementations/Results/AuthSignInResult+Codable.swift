//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import Amplify

extension AuthSignInResult: Equatable {
    public static func == (lhs: AuthSignInResult, rhs: AuthSignInResult) -> Bool {
        lhs.nextStep == rhs.nextStep
    }
}

extension AuthSignInResult: Codable {
    enum CodingKeys: String, CodingKey {
        case nextStep
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let nextStep = try values.decode(AuthSignInStep.self, forKey: .nextStep)
        self.init(nextStep: nextStep)
    }

    public func encode(to encoder: Encoder) throws {
        fatalError("Not Supported")
    }
}

extension AuthSignInStep: Equatable {
    public static func == (lhs: AuthSignInStep, rhs: AuthSignInStep) -> Bool {
        switch (lhs, rhs) {
        case (.confirmSignInWithSMSMFACode, .confirmSignInWithSMSMFACode),
            (.confirmSignUp, .confirmSignUp),
            (.confirmSignInWithCustomChallenge, .confirmSignInWithCustomChallenge),
            (.confirmSignInWithNewPassword, .confirmSignInWithNewPassword),
            (.done, .done):
            return true
        default:
            return false
        }
    }
}

extension AuthSignInStep: Codable {

    enum CodingKeys: String, CodingKey {
        case signInStep
        case codeDeliveryDetails
        case additionalInfo
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if try values.decode(String.self, forKey: .signInStep) == "DONE" {
            self = .done
        } else if try values.decode(String.self, forKey: .signInStep) == "CONFIRM_SIGN_IN_WITH_SMS_MFA_CODE" {
            let codeDeliveryDetails = try values.decode(AuthCodeDeliveryDetails.self, forKey: .codeDeliveryDetails)
            let additionalInfo = try values.decodeIfPresent([String: String].self, forKey: .additionalInfo)
            self = .confirmSignInWithSMSMFACode(
                codeDeliveryDetails,
                additionalInfo)
        } else {
            fatalError("next step type not supported")
        }

    }

    public func encode(to encoder: Encoder) throws {
        fatalError("Not Supported")
    }

}
