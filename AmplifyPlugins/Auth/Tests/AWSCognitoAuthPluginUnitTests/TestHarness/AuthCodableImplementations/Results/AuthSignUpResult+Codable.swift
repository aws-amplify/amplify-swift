//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import Amplify

extension AuthSignUpResult: Equatable {
    public static func == (lhs: AuthSignUpResult, rhs: AuthSignUpResult) -> Bool {
        lhs.nextStep == rhs.nextStep
    }
}

extension AuthSignUpResult: Codable {
    enum CodingKeys: String, CodingKey {
        case nextStep
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let nextStep = try values.decode(AuthSignUpStep.self, forKey: .nextStep)
        self.init(nextStep)
    }

    public func encode(to encoder: Encoder) throws {
        fatalError("Not Supported")
    }
}

extension AuthSignUpStep: Equatable {
    public static func == (lhs: AuthSignUpStep, rhs: AuthSignUpStep) -> Bool {
        switch (lhs, rhs) {
        case (.confirmUser, .confirmUser), (.done, .done):
            return true
        default:
            return false
        }
    }


}

extension AuthSignUpStep: Codable {

    enum CodingKeys: String, CodingKey {
        case signUpStep
        case codeDeliveryDetails
        case additionalInfo
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if try values.decode(String.self, forKey: .signUpStep) == "DONE" {
            self = .done
        } else if try values.decode(String.self, forKey: .signUpStep) == "CONFIRM_SIGN_UP_STEP" {

            let codeDeliveryDetails = try values.decode(
                AuthCodeDeliveryDetails.self,
                forKey: .codeDeliveryDetails)
            let additionalInfo = try values.decode(
                AdditionalInfo.self,
                forKey: .additionalInfo)
            self = .confirmUser(
                codeDeliveryDetails,
                additionalInfo,
                nil)
        } else {
            fatalError("next step type not supported")
        }

    }

    public func encode(to encoder: Encoder) throws {
        fatalError("Not Supported")
    }

}
