//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSMobileClient

extension AWSMobileClientError {
    var message: String {
    switch self {
    case .aliasExists(let message),
         .badRequest(let message),
         .codeDeliveryFailure(let message),
         .codeMismatch(let message),
         .cognitoIdentityPoolNotConfigured(let message),
         .deviceNotRemembered(let message),
         .errorLoadingPage(let message),
         .expiredCode(let message),
         .expiredRefreshToken(let message),
         .federationProviderExists(let message),
         .groupExists(let message),
         .guestAccessNotAllowed(let message),
         .idTokenAndAcceessTokenNotIssued(let message),
         .idTokenNotIssued(let message),
         .identityIdUnavailable(let message),
         .internalError(let message),
         .invalidConfiguration(let message),
         .invalidLambdaResponse(let message),
         .invalidOAuthFlow(let message),
         .invalidParameter(let message),
         .invalidPassword(let message),
         .invalidState(let message),
         .invalidUserPoolConfiguration(let message),
         .limitExceeded(let message),
         .mfaMethodNotFound(let message),
         .notAuthorized(let message),
         .notSignedIn(let message),
         .passwordResetRequired(let message),
         .resourceNotFound(let message),
         .scopeDoesNotExist(let message),
         .securityFailed(let message),
         .softwareTokenMFANotFound(let message),
         .tooManyFailedAttempts(let message),
         .tooManyRequests(let message),
         .unableToSignIn(let message),
         .unexpectedLambda(let message),
         .unknown(let message),
         .userCancelledSignIn(let message),
         .userLambdaValidation(let message),
         .userNotConfirmed(let message),
         .userNotFound(let message),
         .userPoolNotConfigured(let message),
         .usernameExists(let message):
        return message
    }
    }
}
