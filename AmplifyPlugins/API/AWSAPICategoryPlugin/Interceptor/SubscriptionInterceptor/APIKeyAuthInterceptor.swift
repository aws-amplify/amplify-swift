//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCore
import AWSPluginsCore
import Amplify

/// Auth interceptor for API Key based authentication
class APIKeyAuthInterceptor: AuthInterceptor {

    let apikeyProvider: APIKeyProvider

    init(_ apikeyProvider: APIKeyProvider) {
        self.apikeyProvider = apikeyProvider
    }

    /// Intercept the connection request. Adds authorization header and payload query parameters.
    ///
    /// The resulting value of header will contain the base64 string of the following:
    /// * "host": <string> : this is the host for the AppSync endpoint
    /// * "x-amz-date": <string> : UTC timestamp in the following ISO 8601 format: YYYYMMDD'T'HHMMSS'Z'
    /// * "x-api-key": <string> : Api key configured for AppSync API
    /// The value of payload is {}
    /// - Parameter request: Signed request
    func interceptConnection(_ request: AppSyncConnectionRequest,
                             for url: URL) -> AppSyncConnectionRequest {
        guard let host = url.host else {
            Amplify.API.log.warn("[APIKeyAuthInterceptor] interceptConnection missing host")
            return request
        }

        let apiKey  = apikeyProvider.getAPIKey()
        let authHeader = APIKeyAuthenticationHeader(apiKey: apiKey, host: host)
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

    func interceptMessage(_ message: AppSyncMessage, for url: URL) -> AppSyncMessage {
        guard let host = url.host else {
            Amplify.API.log.warn("[APIKeyAuthInterceptor] interceptMessage missing host")
            return message
        }

        switch message.messageType {
        case .subscribe:
            let apiKey  = apikeyProvider.getAPIKey()
            let authHeader = APIKeyAuthenticationHeader(apiKey: apiKey, host: host)
            var payload = message.payload ?? AppSyncMessage.Payload()
            payload.authHeader = authHeader

            let signedMessage = AppSyncMessage(id: message.id,
                                               payload: payload,
                                               type: message.messageType)
            return signedMessage
        default:
            Amplify.API.log.verbose("Message type does not need signing - \(message.messageType)")
        }
        return message
    }
}

/// Authentication header for API key based auth
private class APIKeyAuthenticationHeader: AuthenticationHeader {
    let date: String?
    let apiKey: String

    init(apiKey: String, host: String) {
        let amzDate =  NSDate.aws_clockSkewFixed() as NSDate
        self.date = amzDate.aws_stringValue(AWSDateISO8601DateFormat2)
        self.apiKey = apiKey
        super.init(host: host)
    }

    private enum CodingKeys: String, CodingKey {
        case date = "x-amz-date"
        case apiKey = "x-api-key"
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(apiKey, forKey: .apiKey)
        try super.encode(to: encoder)
    }
}
