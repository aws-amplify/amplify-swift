//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation
import AWSPluginsCore
import Amplify

public struct CognitoIdentityClientConfiguration {
    let region: String
    let signingName = "cognito-identity"
    let encoder: JSONEncoder
    let decoder: JSONDecoder
}

public class CognitoIdentityClient {
    let configuration: CognitoIdentityClientConfiguration

    init(configuration: CognitoIdentityClientConfiguration) {
        self.configuration = configuration
    }
}

extension CognitoIdentityClient: DefaultLogger {
    public static let log: Logger = Amplify.Logging.logger(
        forCategory: CategoryType.auth.displayName,
        forNamespace: "CognitoIdentityClient"
    )

    public var log: Logger {
        Self.log
    }
}

extension CognitoIdentityAction where Input == GetIdInput, Output == GetIdOutputResponse {

    /*
     "GetId":{
       "name":"GetId",
       "http":{
         "method":"POST",
         "requestUri":"/"
       },
       "input":{"shape":"GetIdInput"},
       "output":{"shape":"GetIdResponse"},
       "errors":[
         {"shape":"InvalidParameterException"},
         {"shape":"ResourceNotFoundException"},
         {"shape":"NotAuthorizedException"},
         {"shape":"ResourceConflictException"},
         {"shape":"TooManyRequestsException"},
         {"shape":"InternalErrorException"},
         {"shape":"LimitExceededException"},
         {"shape":"ExternalServiceException"}
       ],
       "authtype":"none"
     },
     */
    static func getID(region: String) -> Self {
        .init(
            name: "GetId",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityService.GetId",
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}

extension CognitoIdentityAction where Input == GetCredentialsForIdentityInput, Output == GetCredentialsForIdentityOutputResponse {
    /*
     "GetCredentialsForIdentity":{
       "name":"GetCredentialsForIdentity",
       "http":{
         "method":"POST",
         "requestUri":"/"
       },
       "input":{"shape":"GetCredentialsForIdentityInput"},
       "output":{"shape":"GetCredentialsForIdentityResponse"},
       "errors":[
         {"shape":"InvalidParameterException"},
         {"shape":"ResourceNotFoundException"},
         {"shape":"NotAuthorizedException"},
         {"shape":"ResourceConflictException"},
         {"shape":"TooManyRequestsException"},
         {"shape":"InvalidIdentityPoolConfigurationException"},
         {"shape":"InternalErrorException"},
         {"shape":"ExternalServiceException"}
       ],
       "authtype":"none"
     }
     */

    static func getCredentialsForIdentity(region: String) -> Self {
        .init(
            name: "GetCredentialsForIdentity",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityService.GetCredentialsForIdentity",
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }

}

extension CognitoIdentityClient: CognitoIdentityBehavior {
    private func request<Input, Output>(
        action: CognitoIdentityAction<Input, Output>,
        input: Input,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) async throws -> Output {
        log.debug("[\(file)] [\(function)] [\(line)] request entry point")
        log.debug("[\(file)] [\(function)] [\(line)] input: \(input)")

        let requestData = try action.encode(input, configuration.encoder)
        log.debug("[\(file)] [\(function)] [\(line)] requestData size size: \(requestData.count)")

        let url = try action.url(region: configuration.region)

        // TODO: generate user-agent
        let userAgent = "amplify-swift/2.x ua/2.0 api/cognito-identity#1.0 os/ios#17.0.1 lang/swift#5.8 cfg/retry-mode#legacy"
        log.debug("[\(file)] [\(function)] [\(line)] userAgent: \(userAgent)")

        var request = URLRequest(url: url)
        request.setValue(action.xAmzTarget, forHTTPHeaderField: "X-Amz-Target")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
        request.setValue(String(requestData.count), forHTTPHeaderField: "Content-Length")
        request.httpMethod = action.method.verb
        request.httpBody = requestData
//        log.debug("[\(file)] [\(function)] [\(line)] unsigned request url: \(url)")
//        let credentials = try await configuration.credentialsProvider.fetchCredentials()
//        let signer = SigV4Signer(
//            credentials: credentials,
//            serviceName: configuration.signingName,
//            region: configuration.region
//        )
//
//        let signedRequest = signer.sign(
//            url: url,
//            method: .post,
//            body: .data(requestData),
//            headers: [
//                "X-Amz-Target": "",
//                "Content-Type": "application/x-amz-json-1.1",
//                "User-Agent": userAgent,
//                "Content-Length": String(requestData.count)
//            ]
//        )

        log.debug("[\(file)] [\(function)] [\(line)] Request URL: \(request.url as Any)")
        log.debug("[\(file)] [\(function)] [\(line)] Request Headers: \(request.allHTTPHeaderFields as Any)")
        log.debug("[\(file)] [\(function)] [\(line)] Starting network request")

        let (responseData, urlResponse) = try await URLSession.shared.upload(
            for: request,
            from: requestData
        )
        log.debug("Completed network request in \(#function) with URLResponse: \(urlResponse)")

        guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
            log.error("""
            Couldn't case from `URLResponse` to `HTTPURLResponse`
            This shouldn't happen. Received URLResponse: \(urlResponse)
            """)
            throw PlaceholderError() // this shouldn't happen
        }

        log.debug("[\(file)] [\(function)] [\(line)] HTTPURLResponse in \(#function): \(httpURLResponse)")
        guard (200..<300).contains(httpURLResponse.statusCode) else {
            log.error("Expected a 2xx status code, received: \(httpURLResponse.statusCode)")
            throw try action.mapError(responseData, httpURLResponse)
        }

        log.debug("[\(file)] [\(function)] [\(line)] Attempting to decode response object in \(#function)")
        let response = try action.decode(responseData, configuration.decoder)
        log.debug("[\(file)] [\(function)] [\(line)] Decoded response in `\(Output.self)`: \(response)")

        return response
    }


    /// Generates (or retrieves) a Cognito ID. Supplying multiple logins will create an implicit linked account.
    /// This is a public API. You do not need any credentials to call this API.
    /// Throws GetIdOutputError
    func getId(input: GetIdInput) async throws -> GetIdOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .getID(region: configuration.region),
            input: input
        )
    }

    /// Returns credentials for the provided identity ID.
    /// Any provided logins will be validated against supported login providers. If the token is for cognito-identity.amazonaws.com,
    /// it will be passed through to AWS Security Token Service with the appropriate role for the token.
    /// This is a public API. You do not need any credentials to call this API.
    /// Throws GetCredentialsForIdentityOutputError
    func getCredentialsForIdentity(
        input: GetCredentialsForIdentityInput
    ) async throws -> GetCredentialsForIdentityOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .getCredentialsForIdentity(
                region: configuration.region
            ),
            input: input
        )
    }
}
