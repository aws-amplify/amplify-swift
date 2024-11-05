//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Code generated by smithy-swift-codegen. DO NOT EDIT!

import class Smithy.Context
import enum Smithy.ClientError
import enum SmithyHTTPAuthAPI.SigningPropertyKeys
import protocol SmithyHTTPAuthAPI.AuthSchemeResolver
import protocol SmithyHTTPAuthAPI.AuthSchemeResolverParameters
import struct SmithyHTTPAuthAPI.AuthOption

public struct CognitoIdentityProviderAuthSchemeResolverParameters: SmithyHTTPAuthAPI.AuthSchemeResolverParameters {
    public let operation: Swift.String
    // Region is used for SigV4 auth scheme
    public let region: Swift.String?
}

public protocol CognitoIdentityProviderAuthSchemeResolver: SmithyHTTPAuthAPI.AuthSchemeResolver {
    // Intentionally empty.
    // This is the parent protocol that all auth scheme resolver implementations of
    // the service CognitoIdentityProvider must conform to.
}

public struct DefaultCognitoIdentityProviderAuthSchemeResolver: CognitoIdentityProviderAuthSchemeResolver {

    public func resolveAuthScheme(params: SmithyHTTPAuthAPI.AuthSchemeResolverParameters) throws -> [SmithyHTTPAuthAPI.AuthOption] {
        var validAuthOptions = [SmithyHTTPAuthAPI.AuthOption]()
        guard let serviceParams = params as? CognitoIdentityProviderAuthSchemeResolverParameters else {
            throw Smithy.ClientError.authError("Service specific auth scheme parameters type must be passed to auth scheme resolver.")
        }
        switch serviceParams.operation {
            case "associateSoftwareToken":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "changePassword":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "confirmDevice":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "confirmForgotPassword":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "confirmSignUp":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "deleteUser":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "deleteUserAttributes":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "forgetDevice":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "forgotPassword":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "getDevice":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "getUser":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "getUserAttributeVerificationCode":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "globalSignOut":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "initiateAuth":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "listDevices":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "resendConfirmationCode":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "respondToAuthChallenge":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "revokeToken":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "setUserMFAPreference":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "setUserSettings":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "signUp":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "updateAuthEventFeedback":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "updateDeviceStatus":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "updateUserAttributes":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "verifySoftwareToken":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "verifyUserAttribute":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            default:
                var sigV4Option = SmithyHTTPAuthAPI.AuthOption(schemeID: "aws.auth#sigv4")
                sigV4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingName, value: "cognito-idp")
                guard let region = serviceParams.region else {
                    throw Smithy.ClientError.authError("Missing region in auth scheme parameters for SigV4 auth scheme.")
                }
                sigV4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingRegion, value: region)
                validAuthOptions.append(sigV4Option)
        }
        return validAuthOptions
    }

    public func constructParameters(context: Smithy.Context) throws -> SmithyHTTPAuthAPI.AuthSchemeResolverParameters {
        guard let opName = context.getOperation() else {
            throw Smithy.ClientError.dataNotFound("Operation name not configured in middleware context for auth scheme resolver params construction.")
        }
        let opRegion = context.getRegion()
        return CognitoIdentityProviderAuthSchemeResolverParameters(operation: opName, region: opRegion)
    }
}