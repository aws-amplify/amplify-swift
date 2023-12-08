//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct PasswordlessHelper {

    static func getCodeDeliveryDetails(parameters: [String: String]) -> AuthCodeDeliveryDetails {

        var deliveryDestination = DeliveryDestination.unknown(nil)
        var attribute: AuthUserAttributeKey? = nil

        // Retrieve Delivery medium and destination
        let medium = parameters["deliveryMedium"]
        let destination = parameters["destination"]
        if medium == "SMS" {
            deliveryDestination = .sms(destination)
        } else if medium == "EMAIL" {
            deliveryDestination = .email(destination)
        }

        // Retrieve attribute name
        if let attributeName = parameters["attributeName"] {
            attribute = AuthUserAttributeKey(rawValue: attributeName)
        }

        return AuthCodeDeliveryDetails(
            destination: deliveryDestination,
            attributeKey: attribute)
    }

    static func getResultForChallengeParams(
        _ challengeParams: [String: String]?,
        signInMethod: PasswordlessCustomAuthSignInMethod
    ) throws -> AuthSignInResult {
        if let errorCode = challengeParams?["errorCode"]{
            switch errorCode {
            case "CodeMismatchException":
                throw AuthError.service(
                    "Provided code does not match what the server was expecting.",
                    AuthPluginErrorConstants.codeMismatchError,
                    AWSCognitoAuthError.codeMismatch)
            default:
                throw AuthError.service(
                    "Unknown service error occurred. Error code:  \(errorCode)",
                    AmplifyErrorMessages.shouldNotHappenReportBugToAWS(), nil)
            }
        }

        // Ask the customer for the next step
        switch signInMethod{
        case .otp:
            return .init(nextStep: .confirmSignInWithOTP(
                PasswordlessHelper.getCodeDeliveryDetails(parameters: challengeParams ?? [:]), nil))
        case .magicLink:
            return .init(nextStep: .confirmSignInWithMagicLink(
                PasswordlessHelper.getCodeDeliveryDetails(parameters: challengeParams ?? [:]), nil))
        }
    }

}
