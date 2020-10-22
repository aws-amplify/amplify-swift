//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSMobileClient

public class AWSAuthService: AWSAuthServiceBehavior {

    public init() {}

    public func getCredentialsProvider() -> AWSCredentialsProvider {
        return AmplifyAWSCredentialsProvider()
    }

    public func getIdentityId() -> Result<String, AuthError> {
        var result: Result<String, AuthError>?
        let semaphore = DispatchSemaphore(value: 0)
        _ = Amplify.Auth.fetchAuthSession { event in
            defer {
                semaphore.signal()
            }

            switch event {
            case .success(let session):
                result = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
            case .failure(let error):
                result = .failure(error)

            }
        }
        semaphore.wait()
        guard let validResult = result else {
            return .failure(AuthError.unknown("""
            Did not receive a valid response from fetchAuthSession for identityId.
            """))
        }
        return validResult
    }

    // This algorithm was heavily based on the implementation here:
    // https://github.com/aws-amplify/aws-sdk-ios/blob/main/AWSAuthSDK/Sources/AWSMobileClient/AWSMobileClientExtensions.swift#L29
    public func getTokenClaims(tokenString: String) -> Result<[String: AnyObject], AuthError> {
        let tokenSplit = tokenString.split(separator: ".")
        guard tokenSplit.count > 2 else {
            return .failure(.validation("", "Token is not valid base64 encoded string.", "", nil))
        }

        //Add ability to do URL decoding
        //https://stackoverflow.com/questions/40915607/how-can-i-decode-jwt-json-web-token-token-in-swift
        let claims = tokenSplit[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let paddedLength = claims.count + (4 - (claims.count % 4)) % 4
        //JWT is not padded with =, pad it if necessary
        let updatedClaims = claims.padding(toLength: paddedLength, withPad: "=", startingAt: 0)
        let encodedData = Data(base64Encoded: updatedClaims, options: .ignoreUnknownCharacters)

        guard let claimsData = encodedData else {
            return .failure(
                .validation("", "Cannot get claims in `Data` form. Token is not valid base64 encoded string.",
                            "", nil))
        }

        let jsonObject: Any?
        do {
            jsonObject = try JSONSerialization.jsonObject(with: claimsData, options: [])
        } catch {
            return .failure(
                .validation("", "Cannot get claims in `Data` form. Token is not valid JSON string.",
                            "", error))
        }

        guard let convertedDictionary = jsonObject as? [String: AnyObject] else {
            return .failure(
                .validation("", "Cannot get claims in `Data` form. Unable to convert to [String: AnyObject].",
                            "", nil))
        }
        return .success(convertedDictionary)
    }

    public func getToken() -> Result<String, AuthError> {
        var result: Result<String, AuthError>?
        let semaphore = DispatchSemaphore(value: 0)
        _ = Amplify.Auth.fetchAuthSession { [weak self] event in

            defer {
                semaphore.signal()
            }

            switch event {
            case .success(let session):
                result = self?.getTokenString(from: session)
            case .failure(let error):
                result = .failure(error)

            }
        }
        semaphore.wait()
        guard let validResult = result else {
            return .failure(AuthError.unknown("""
            Did not receive a valid response from fetchAuthSession for get token.
            """))
        }
        return validResult
    }

    private func getTokenString(from authSession: AuthSession) -> Result<String, AuthError>? {
        if let result = (authSession as? AuthCognitoTokensProvider)?.getCognitoTokens() {
            switch result {
            case .success(let tokens):
                return .success(tokens.accessToken)
            case .failure(let error):
                return .failure(error)
            }
        }
        return nil
    }
}
