//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import AWSPluginsCore

class CognitoUserPoolsAuthInterceptor: AuthInterceptor {

    let authProvider: AuthTokenProvider

    init(_ authProvider: AuthTokenProvider) {
        self.authProvider = authProvider
    }

    func interceptMessage(_ message: AppSyncMessage, for endpoint: URL) -> AppSyncMessage {
        let host = endpoint.host!
        var jwtToken: String?
        getToken { (token, error) in
            jwtToken = token
        }
        guard let token = jwtToken else {
            return message
        }
        switch message.messageType {
        case .subscribe:
            let authHeader = UserPoolsAuthenticationHeader(token: token, host: host)
            var payload = message.payload ?? AppSyncMessage.Payload()
            payload.authHeader = authHeader

            let signedMessage = AppSyncMessage(id: message.id,
                                               payload: payload,
                                               type: message.messageType)
            return signedMessage
        default:
            print("Message type does not need signing - \(message.messageType)")
        }
        return message
    }

    func interceptConnection(_ request: AppSyncConnectionRequest, for endpoint: URL) -> AppSyncConnectionRequest {
        let host = endpoint.host!
        var jwtToken: String?
        getToken { (token, error) in
            jwtToken = token
        }
        guard let token = jwtToken else {
            return request
        }
        let authHeader = UserPoolsAuthenticationHeader(token: token, host: host)
        let base64Auth = AppSyncJSONHelper.base64AuthenticationBlob(authHeader)

        let payloadData = SubscriptionConstants.emptyPayload.data(using: .utf8)
        let payloadBase64 = payloadData?.base64EncodedString()

        guard var urlComponents = URLComponents(url: request.url, resolvingAgainstBaseURL: false) else {
            return request
        }
        let headerQuery = URLQueryItem(name: RealtimeProviderConstants.header, value: base64Auth)
        let payloadQuery = URLQueryItem(name: RealtimeProviderConstants.payload, value: payloadBase64)
        urlComponents.queryItems = [headerQuery, payloadQuery]
        guard let url = urlComponents.url else {
            return request
        }
        let signedRequest = AppSyncConnectionRequest(url: url)
        return signedRequest
    }

    private func getToken(_ callback: (String?, Error?) -> Void) {

        let tokenResult = authProvider.getToken()
        switch tokenResult {
        case .success(let token):
            callback(token, nil)
        case .failure(let error):
            callback(nil, error)
        }
    }
}

/// Authentication header for user pool based auth
private class UserPoolsAuthenticationHeader: AuthenticationHeader {
    let authorization: String

    init(token: String, host: String) {
        self.authorization = token
        super.init(host: host)
    }

    private enum CodingKeys: String, CodingKey {
        case authorization = "Authorization"
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(authorization, forKey: .authorization)
        try super.encode(to: encoder)
    }
}
