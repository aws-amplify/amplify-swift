//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCore
import AWSPluginsCore
import Amplify
import AppSyncRealTimeClient

class IAMAuthInterceptor: AuthInterceptor {

    private static let lowercasedHeaderKeys: Set = [SubscriptionConstants.authorizationkey.lowercased(),
                                                    RealtimeProviderConstants.acceptKey.lowercased(),
                                                    RealtimeProviderConstants.contentEncodingKey.lowercased(),
                                                    RealtimeProviderConstants.contentTypeKey.lowercased(),
                                                    RealtimeProviderConstants.amzDate.lowercased(),
                                                    RealtimeProviderConstants.iamSecurityTokenKey.lowercased()]

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
        let mutableRequest = NSMutableURLRequest(url: endpoint)
        return getAuthHeader(host: host,
                             mutableRequest: mutableRequest,
                             signer: signer,
                             amzDate: date,
                             payload: payload)
    }

    func getAuthHeader(host: String,
                       mutableRequest: NSMutableURLRequest,
                       signer: AWSSignatureV4Signer,
                       amzDate: String,
                       payload: String) -> IAMAuthenticationHeader {
        let semaphore = DispatchSemaphore(value: 0)
        mutableRequest.httpMethod = "POST"
        mutableRequest.addValue(RealtimeProviderConstants.iamAccept,
                                forHTTPHeaderField: RealtimeProviderConstants.acceptKey)
        mutableRequest.addValue(amzDate, forHTTPHeaderField: RealtimeProviderConstants.amzDate)
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
        let remainingHeaders = mutableRequest.allHTTPHeaderFields?.filter { (header) -> Bool in
            return !Self.lowercasedHeaderKeys.contains(header.key.lowercased())
        }

        return IAMAuthenticationHeader(host: host,
                                       authorization: authorization,
                                       securityToken: securityToken,
                                       amzDate: amzDate,
                                       accept: RealtimeProviderConstants.iamAccept,
                                       contentEncoding: RealtimeProviderConstants.iamEncoding,
                                       contentType: RealtimeProviderConstants.iamConentType,
                                       remainingHeaders: remainingHeaders)
    }
}

/// Authentication header for IAM based auth
class IAMAuthenticationHeader: AuthenticationHeader {
    let authorization: String
    let securityToken: String
    let amzDate: String
    let accept: String
    let contentEncoding: String
    let contentType: String
    let remainingHeaders: [String: String]?

    init(host: String,
         authorization: String,
         securityToken: String,
         amzDate: String,
         accept: String,
         contentEncoding: String,
         contentType: String,
         remainingHeaders: [String: String]?) {
        self.authorization = authorization
        self.securityToken = securityToken
        self.amzDate = amzDate
        self.accept = accept
        self.contentEncoding = contentEncoding
        self.contentType = contentType
        self.remainingHeaders = remainingHeaders
        super.init(host: host)
    }

    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        var intValue: Int?
        init?(intValue: Int) {
            return nil
        }
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        try container.encode(authorization,
                             forKey: DynamicCodingKeys(stringValue: SubscriptionConstants.authorizationkey)!)
        try container.encode(securityToken,
                             forKey: DynamicCodingKeys(stringValue: RealtimeProviderConstants.iamSecurityTokenKey)!)
        try container.encode(amzDate,
                             forKey: DynamicCodingKeys(stringValue: RealtimeProviderConstants.amzDate)!)
        try container.encode(accept,
                             forKey: DynamicCodingKeys(stringValue: RealtimeProviderConstants.acceptKey)!)
        try container.encode(contentEncoding,
                             forKey: DynamicCodingKeys(stringValue: RealtimeProviderConstants.contentEncodingKey)!)
        try container.encode(contentType,
                             forKey: DynamicCodingKeys(stringValue: RealtimeProviderConstants.contentTypeKey)!)
        if let headers = remainingHeaders {
            for (key, value) in headers {
                try container.encode(value, forKey: DynamicCodingKeys(stringValue: key)!)
            }
        }
        try super.encode(to: encoder)
    }
}
