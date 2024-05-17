//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@_spi(WebSocket) import AWSPluginsCore
import InternalAmplifyCredentials
import Amplify
import AWSClientRuntime
import ClientRuntime

class IAMAuthInterceptor {

    let authProvider: CredentialsProviding
    let region: AWSRegionType

    init(_ authProvider: CredentialsProviding, region: AWSRegionType) {
        self.authProvider = authProvider
        self.region = region
    }

    func getAuthHeader(
        _ endpoint: URL,
        with payload: String,
        signer: AWSSignatureV4Signer = AmplifyAWSSignatureV4Signer()
    ) async -> AppSyncRealTimeRequestAuth.IAM? {
        guard let host = endpoint.host else {
            return nil
        }

        /// The process of getting the auth header for an IAM based authentication request is as follows:
        ///
        /// 1. A request is created with the IAM based auth headers (date,  accept, content encoding, content type, and
        /// additional headers.
        let requestBuilder = SdkHttpRequestBuilder()
            .withHost(host)
            .withPath(endpoint.path)
            .withMethod(.post)
            .withPort(443)
            .withProtocol(.https)
            .withHeader(name: "accept", value: "application/json, text/javascript")
            .withHeader(name: "content-encoding", value: "amz-1.0")
            .withHeader(name: URLRequestConstants.Header.contentType, value: "application/json; charset=UTF-8")
            .withHeader(name: URLRequestConstants.Header.host, value: host)
            .withBody(.data(Data(payload.utf8)))

        /// 2. The request is SigV4 signed by using all the available headers on the request. By signing the request, the signature is added to
        /// the request headers as authorization and security token.
        do {
            guard let urlRequest = try await signer.sigV4SignedRequest(requestBuilder: requestBuilder,
                                                                 credentialsProvider: authProvider,
                                                                 signingName: "appsync",
                                                                 signingRegion: region,
                                                                 date: Date()) else {
                Amplify.Logging.error("Unable to sign request")
                return nil
            }

            // TODO: Using long lived credentials without getting a session with security token will fail
            // since the session token does not exist on the signed request, and is an empty string.
            // Once Amplify.Auth is ready to be integrated, this code path needs to be re-tested.
            let headers = urlRequest.headers.headers.reduce([String: JSONValue]()) { partialResult, header in
                switch header.name.lowercased() {
                case "authorization", "x-amz-date", "x-amz-security-token":
                    guard let headerValue = header.value.first else {
                        return partialResult
                    }
                    return partialResult.merging([header.name.lowercased(): .string(headerValue)]) { $1 }
                default:
                    return partialResult
                }
            }

            return .init(
                host: host,
                authToken: headers["authorization"]?.stringValue ?? "",
                securityToken: headers["x-amz-security-token"]?.stringValue ?? "",
                amzDate: headers["x-amz-date"]?.stringValue ?? ""
            )
        } catch {
            Amplify.Logging.error("Unable to sign request")
            return nil
        }
    }
}

extension IAMAuthInterceptor: WebSocketInterceptor {
    func interceptConnection(url: URL) async -> URL {
        let connectUrl = AppSyncRealTimeClientFactory.appSyncApiEndpoint(url).appendingPathComponent("connect")
        guard let authHeader = await getAuthHeader(connectUrl, with: "{}") else {
            return connectUrl
        }
        
        return AppSyncRealTimeRequestAuth.URLQuery(
            header: .iam(authHeader)
        ).withBaseURL(url)
    }
}

extension IAMAuthInterceptor: AppSyncRequestInterceptor {
    func interceptRequest(
        event: AppSyncRealTimeRequest,
        url: URL
    ) async -> AppSyncRealTimeRequest {
        guard case .start(let request) = event else {
            return event
        }

        let authHeader = await getAuthHeader(
            AppSyncRealTimeClientFactory.appSyncApiEndpoint(url),
            with: request.data)
        return .start(.init(
            id: request.id,
            data: request.data,
            auth: authHeader.map { .iam($0) }
        ))
    }
}
