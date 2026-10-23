//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Reads the claims of a JWT without verifying it.
///
/// A copy of `AWSAuthService.getTokenClaims(tokenString:)` (`AWSPluginsCore/Auth/AWSAuthService.swift`),
/// so the engine does not depend on `AWSPluginsCore`. The decoding steps are the same, in the same
/// order, and each failure carries the same message. `AWSAuthService` reports failures as
/// `AuthError.validation("", message, "", underlyingError)`; this reports them as `EngineJWT.Failure`.
///
/// `EngineJWTTests` checks both over the same table of tokens, including malformed ones.
package enum EngineJWT {

    /// Why a token's claims could not be read.
    package enum Failure: Error {

        /// Fewer than three non-empty `.`-separated segments.
        case malformedToken

        /// The payload segment is not base64 (after base64url conversion and padding).
        case invalidBase64

        /// The payload is not JSON.
        case invalidJSON(Error)

        /// The payload is JSON, but not an object.
        case notAnObject

        /// The message `AWSAuthService` puts in the `AuthError` it returns for the same failure.
        package var message: String {
            switch self {
            case .malformedToken:
                return "Token is not valid base64 encoded string."
            case .invalidBase64:
                return "Cannot get claims in `Data` form. Token is not valid base64 encoded string."
            case .invalidJSON:
                return "Cannot get claims in `Data` form. Token is not valid JSON string."
            case .notAnObject:
                return "Cannot get claims in `Data` form. Unable to convert to [String: AnyObject]."
            }
        }

        /// The error `AWSAuthService` puts in the `AuthError` it returns for the same failure.
        package var underlyingError: Error? {
            if case .invalidJSON(let error) = self {
                return error
            }
            return nil
        }
    }

    // This algorithm was heavily based on the implementation here:
    //  https://github.com/aws-amplify/aws-sdk-ios/blob/main/AWSAuthSDK/Sources/AWSMobileClient/AWSMobileClientExtensions.swift#L29
    /// Returns the claims in the payload segment of `token`.
    package static func claims(_ token: String) -> Result<[String: AnyObject], Failure> {
        let tokenSplit = token.split(separator: ".")
        guard tokenSplit.count > 2 else {
            return .failure(.malformedToken)
        }

        // Add ability to do URL decoding
        // https://stackoverflow.com/questions/40915607/how-can-i-decode-jwt-json-web-token-token-in-swift
        let claims = tokenSplit[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let paddedLength = claims.count + (4 - (claims.count % 4)) % 4
        // JWT is not padded with =, pad it if necessary
        let updatedClaims = claims.padding(toLength: paddedLength, withPad: "=", startingAt: 0)
        let encodedData = Data(base64Encoded: updatedClaims, options: .ignoreUnknownCharacters)

        guard let claimsData = encodedData else {
            return .failure(.invalidBase64)
        }

        let jsonObject: Any?
        do {
            jsonObject = try JSONSerialization.jsonObject(with: claimsData, options: [])
        } catch {
            return .failure(.invalidJSON(error))
        }

        guard let convertedDictionary = jsonObject as? [String: AnyObject] else {
            return .failure(.notAnObject)
        }
        return .success(convertedDictionary)
    }
}
