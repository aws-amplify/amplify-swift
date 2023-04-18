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

    let authProvider: AWSCredentialsProvider
    let region: AWSRegionType

    init(_ authProvider: AWSCredentialsProvider, region: AWSRegionType) {
        self.authProvider = authProvider
        self.region = region
    }

    func interceptMessage(
        _ message: AppSyncMessage,
        for endpoint: URL,
        completion: @escaping (AppSyncMessage) -> Void) {

            guard case .subscribe = message.messageType else {
                Amplify.API.log.verbose("Message type does not need signing - \(message.messageType)")
                completion(message)
                return
            }
            guard let helper = HeaderIAMSigningHelper(
                endpoint: endpoint,
                payload: message.payload?.data ?? "",
                region: region) else {
                completion(message)
                return
            }
            helper.sign(authProvider: authProvider) { signedHeader in
                var payload = message.payload ?? AppSyncMessage.Payload()
                payload.authHeader = signedHeader
                let signedMessage = AppSyncMessage(
                    id: message.id,
                    payload: payload,
                    type: message.messageType)
                completion(signedMessage)
                return
            }
        }

    func interceptConnection(
        _ request: AppSyncConnectionRequest,
        for endpoint: URL,
        completion: @escaping (AppSyncConnectionRequest) -> Void) {
            let url = endpoint.appendingPathComponent(RealtimeProviderConstants.iamConnectPath)
            let payloadString = SubscriptionConstants.emptyPayload

            guard let helper = HeaderIAMSigningHelper(
                endpoint: url,
                payload: payloadString,
                region: region) else {
                completion(request)
                return
            }

            helper.sign(authProvider: authProvider) { signedHeader in
                let base64Auth = AppSyncJSONHelper.base64AuthenticationBlob(signedHeader)

                let payloadData = payloadString.data(using: .utf8)
                let payloadBase64 = payloadData?.base64EncodedString()

                guard var urlComponents = URLComponents(
                    url: request.url,
                    resolvingAgainstBaseURL: false) else {
                    completion(request)
                    return
                }
                let headerQuery = URLQueryItem(name: RealtimeProviderConstants.header, value: base64Auth)
                let payloadQuery = URLQueryItem(name: RealtimeProviderConstants.payload, value: payloadBase64)
                urlComponents.queryItems = [headerQuery, payloadQuery]
                guard let signedUrl = urlComponents.url else {
                    completion(request)
                    return
                }
                let signedRequest = AppSyncConnectionRequest(url: signedUrl)
                completion(signedRequest)
                return
            }
        }

    func interceptMessage(
        _ message: AppSyncMessage,
        for endpoint: URL) -> AppSyncMessage {

            guard case .subscribe = message.messageType else {
                Amplify.API.log.verbose("Message type does not need signing - \(message.messageType)")
                return message
            }
            let authHeader = getAuthHeader(endpoint, with: message.payload?.data ?? "")
            var payload = message.payload ?? AppSyncMessage.Payload()
            payload.authHeader = authHeader
            let signedMessage = AppSyncMessage(
                id: message.id,
                payload: payload,
                type: message.messageType)
            return signedMessage
        }

    func interceptConnection(
        _ request: AppSyncConnectionRequest,
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

    func getAuthHeader(
        _ endpoint: URL,
        with payload: String) -> IAMAuthenticationHeader? {

            guard let helper = HeaderIAMSigningHelper(
                endpoint: endpoint,
                payload: payload,
                region: region) else {
                return nil
            }
            var signedHeader: IAMAuthenticationHeader?
            let semaphore = DispatchSemaphore(value: 0)
            helper.sign(authProvider: authProvider) { header in
                signedHeader = header
                semaphore.signal()
            }
            semaphore.wait()
            return signedHeader
        }
}
