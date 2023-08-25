//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation
import ClientRuntime

typealias AWSRegionType = String

struct IAMURLRequestInterceptor: URLRequestInterceptor {
    let iamCredentialsProvider: IAMCredentialsProvider
    let region: AWSRegionType
    let endpointType: AWSAPICategoryPluginEndpointType

    init(iamCredentialsProvider: IAMCredentialsProvider,
         region: AWSRegionType,
         endpointType: AWSAPICategoryPluginEndpointType) {
        self.iamCredentialsProvider = iamCredentialsProvider
        self.region = region
        self.endpointType = endpointType
    }

    func intercept(_ request: URLRequest) async throws -> URLRequest {
        var request = request

        guard let url = request.url else {
            throw APIError.unknown("Could not get url from mutable request", "")
        }
        guard let host = url.host else {
            throw APIError.unknown("Could not get host from mutable request", "")
        }

        request.setValue(URLRequestConstants.ContentType.applicationJson, forHTTPHeaderField: URLRequestConstants.Header.contentType)
        request.setValue(host, forHTTPHeaderField: "host")
        request.setValue(AmplifyAWSServiceConfiguration.frameworkMetaData().description, forHTTPHeaderField: URLRequestConstants.Header.userAgent)

        let httpMethod = (request.httpMethod?.uppercased())
            .flatMap(HttpMethodType.init(rawValue:)) ?? .get

        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        let requestBuilder = SdkHttpRequestBuilder()
            .withHost(host)
            .withPath(url.path)
            .withQueryItems(queryItems)
            .withMethod(httpMethod)
            .withPort(443)
            .withProtocol(.https)
            .withHeaders(.init(request.allHTTPHeaderFields ?? [:]))
            .withBody(.data(request.httpBody))

        let signingName: String
        switch endpointType {
        case .graphQL:
            signingName = URLRequestConstants.appSyncServiceName
        case .rest:
            signingName = URLRequestConstants.apiGatewayServiceName
        }

        guard let urlRequest = try await AmplifyAWSSignatureV4Signer().sigV4SignedRequest(
            requestBuilder: requestBuilder,
            credentialsProvider: iamCredentialsProvider.getCredentialsProvider(),
            signingName: signingName,
            signingRegion: region,
            date: Date()
        ) else {
            throw APIError.unknown("Unable to sign request", "")
        }

        for header in urlRequest.headers.headers {
            request.setValue(header.value.joined(separator: ","), forHTTPHeaderField: header.name)
        }

        return request
    }
}
