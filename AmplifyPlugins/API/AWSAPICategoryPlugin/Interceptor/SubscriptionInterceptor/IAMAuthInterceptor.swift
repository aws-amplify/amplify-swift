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

    private static let defaultLowercasedHeaderKeys: Set = [SubscriptionConstants.authorizationkey.lowercased(),
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

    func interceptMessage(_ message: AppSyncMessage, for endpoint: URL, completion: @escaping (AppSyncMessage) -> Void) {

    }

    func interceptConnection(_ request: AppSyncConnectionRequest, for endpoint: URL, completion: @escaping (AppSyncConnectionRequest) -> Void) {

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

    /// The process of getting the auth header for an IAM based authencation request is as follows:
    ///
    /// 1. A request is created with the IAM based auth headers (date,  accept, content encoding, content type, and
    /// additional headers from the `mutableRequest`.
    ///
    /// 2. The request is SigV4 signed by using all the available headers on the request.
    /// By signing the request, the signature is added to
    /// the request headers as authorization and security token.
    ///
    /// 3. The signed request headers are stored in an `IAMAuthenticationHeader` object, used for further encoding to
    /// be added to the request for establishing the subscription connection.
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
        let additionalHeaders = mutableRequest.allHTTPHeaderFields?.filter {
            !Self.defaultLowercasedHeaderKeys.contains($0.key.lowercased())
        }

        return IAMAuthenticationHeader(host: host,
                                       authorization: authorization,
                                       securityToken: securityToken,
                                       amzDate: amzDate,
                                       accept: RealtimeProviderConstants.iamAccept,
                                       contentEncoding: RealtimeProviderConstants.iamEncoding,
                                       contentType: RealtimeProviderConstants.iamConentType,
                                       additionalHeaders: additionalHeaders)
    }
}

/// Stores the headers for an IAM based authentication. This object can be serialized to a JSON object and passed as the
/// headers value for establishing subscription connections. This is used as part of the overall interceptor logic
/// which expects a subclass of `AuthenticationHeader` to be returned.
/// See `IAMAuthInterceptor.getAuthHeader` for more details.
class IAMAuthenticationHeader: AuthenticationHeader {
    let authorization: String
    let securityToken: String
    let amzDate: String
    let accept: String
    let contentEncoding: String
    let contentType: String

    /// Additional headers that are not one of the expected headers in the request, but because additional headers are
    /// also signed (and added the authorization header), they are required to be stored here to be further encoded.
    let additionalHeaders: [String: String]?

    init(host: String,
         authorization: String,
         securityToken: String,
         amzDate: String,
         accept: String,
         contentEncoding: String,
         contentType: String,
         additionalHeaders: [String: String]?) {
        self.authorization = authorization
        self.securityToken = securityToken
        self.amzDate = amzDate
        self.accept = accept
        self.contentEncoding = contentEncoding
        self.contentType = contentType
        self.additionalHeaders = additionalHeaders
        super.init(host: host)
    }

    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        var intValue: Int?
        init?(intValue: Int) {
            // We are not using this, thus just return nil. If we don't return nil, then it is expected all of the
            // stored properties are initialized, forcing the implementation to have logic that maintains the two
            // properties `stringValue` and `intValue`. Since we don't have a string representation of an int value
            // and aren't using int values for determining the coding key, then simply return nil since the encoder
            // will always pass in the header key string.
            self.intValue = intValue
            self.stringValue = ""

        }
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        // Force unwrapping when creating a `DynamicCodingKeys` will always be successful since the string constructor
        // will never return nil even though the constructor is optional (conformance to CodingKey).
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
        if let headers = additionalHeaders {
            for (key, value) in headers {
                try container.encode(value, forKey: DynamicCodingKeys(stringValue: key)!)
            }
        }
        try super.encode(to: encoder)
    }
}
