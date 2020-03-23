//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCore
import AWSPluginsCore
import Amplify
import AppSyncRealTimeClient

class IAMAuthInterceptor: AuthInterceptor {

    let authProvider: AWSCredentialsProvider
    let region: AWSRegionType

    init(_ authProvider: AWSCredentialsProvider, region: AWSRegionType) {
        self.authProvider = authProvider
        self.region = region
    }

    func interceptMessage(_ message: AppSyncMessage, for endpoint: URL) -> AppSyncMessage {
        switch message.messageType {
        case .subscribe:
            let authHeader = getAuthHeader(endpoint, with: message.payload?.data ?? "")
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

    func interceptConnection(_ request: AppSyncConnectionRequest,
                             for endpoint: URL) -> AppSyncConnectionRequest {
        let url = endpoint.appendingPathComponent(RealtimeProviderConstants.iamConnectPath)
        let payloadString = SubscriptionConstants.emptyPayload
        guard let authHeader = getAuthHeader(url, with: payloadString) else {
            return request
        }
        let base64Auth = AppSyncJSONHelper.base64AuthenticationBlob(authHeader)

        let payloadData = payloadString.data(using: .utf8)
        let payloadBase64 = payloadData?.base64EncodedString()

        guard var urlComponents = URLComponents(url: request.url, resolvingAgainstBaseURL: false) else {
            return request
        }
        let headerQuery = URLQueryItem(name: RealtimeProviderConstants.header, value: base64Auth)
        let payloadQuery = URLQueryItem(name: RealtimeProviderConstants.payload, value: payloadBase64)
        urlComponents.queryItems = [headerQuery, payloadQuery]
        guard let signedUrl = urlComponents.url else {
            return request
        }
        let signedRequest = AppSyncConnectionRequest(url: signedUrl)
        return signedRequest
    }

    final private func getAuthHeader(_ endpoint: URL, with payload: String) -> IAMAuthenticationHeader? {
        guard let host = endpoint.host else {
            return nil
        }
        let amzDate =  NSDate.aws_clockSkewFixed() as NSDate
        guard let date = amzDate.aws_stringValue(AWSDateISO8601DateFormat2) else {
            return nil
        }
        guard let awsEndpoint = AWSEndpoint(region: region,
                                            serviceName: SubscriptionConstants.appsyncServiceName,
                                            url: endpoint) else {
            return nil
        }
        let signer: AWSSignatureV4Signer = AWSSignatureV4Signer(credentialsProvider: authProvider,
                                                                endpoint: awsEndpoint)
        let semaphore = DispatchSemaphore(value: 0)
        let mutableRequest = NSMutableURLRequest(url: endpoint)
        mutableRequest.httpMethod = "POST"
        mutableRequest.addValue(RealtimeProviderConstants.iamAccept,
                                forHTTPHeaderField: RealtimeProviderConstants.acceptKey)
        mutableRequest.addValue(date, forHTTPHeaderField: RealtimeProviderConstants.amzDate)
        mutableRequest.addValue(RealtimeProviderConstants.iamEncoding,
                                forHTTPHeaderField: RealtimeProviderConstants.contentEncodingKey)
        mutableRequest.addValue(RealtimeProviderConstants.iamConentType,
                                forHTTPHeaderField: RealtimeProviderConstants.contentTypeKey)
        mutableRequest.httpBody = payload.data(using: .utf8)

        signer.interceptRequest(mutableRequest).continueWith { _ in
            semaphore.signal()
            return nil
        }
        semaphore.wait()
        let authorization = mutableRequest.allHTTPHeaderFields?[SubscriptionConstants.authorizationkey] ?? ""
        let securityToken = mutableRequest.allHTTPHeaderFields?[RealtimeProviderConstants.iamSecurityTokenKey] ?? ""
        let authHeader = IAMAuthenticationHeader(authorization: authorization,
                                                 host: host,
                                                 token: securityToken,
                                                 date: date,
                                                 accept: RealtimeProviderConstants.iamAccept,
                                                 contentEncoding: RealtimeProviderConstants.iamEncoding,
                                                 contentType: RealtimeProviderConstants.iamConentType)
        return authHeader
    }
}

/// Authentication header for IAM based auth
private class IAMAuthenticationHeader: AuthenticationHeader {
    let authorization: String
    let securityToken: String
    let date: String
    let accept: String
    let contentEncoding: String
    let contentType: String

    init(authorization: String,
         host: String,
         token: String,
         date: String,
         accept: String,
         contentEncoding: String,
         contentType: String) {
        self.date = date
        self.authorization = authorization
        self.securityToken = token
        self.accept = accept
        self.contentEncoding = contentEncoding
        self.contentType = contentType
        super.init(host: host)
    }

    private enum CodingKeys: String, CodingKey {
        case authorization = "Authorization"
        case accept
        case contentEncoding = "content-encoding"
        case contentType = "content-type"
        case date = "x-amz-date"
        case securityToken = "x-amz-security-token"
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(authorization, forKey: .authorization)
        try container.encode(accept, forKey: .accept)
        try container.encode(contentEncoding, forKey: .contentEncoding)
        try container.encode(contentType, forKey: .contentType)
        try container.encode(date, forKey: .date)
        try container.encode(securityToken, forKey: .securityToken)
        try super.encode(to: encoder)
    }
}
