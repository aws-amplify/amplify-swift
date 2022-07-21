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
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            throw APIError.unknown("Could not get mutable request", "")
        }
        guard let url = mutableRequest.url else {
            throw APIError.unknown("Could not get url from mutable request", "")
        }
        guard let host = url.host else {
            throw APIError.unknown("Could not get host from mutable request", "")
        }

        mutableRequest.setValue(URLRequestConstants.ContentType.applicationJson, forHTTPHeaderField: URLRequestConstants.Header.contentType)
        mutableRequest.setValue(host, forHTTPHeaderField: "host")
        mutableRequest.setValue(AWSAPIPluginsCore.baseUserAgent(), forHTTPHeaderField: URLRequestConstants.Header.userAgent)

        let httpMethod = HttpMethodType(rawValue: mutableRequest.httpMethod.uppercased()) ?? .get

        let requestBuilder = SdkHttpRequestBuilder()
            .withHost(host)
            .withPath(url.path)
            .withMethod(httpMethod)
            .withPort(443)
            .withProtocol(.https)
            .withHeaders(.init(mutableRequest.allHTTPHeaderFields ?? [:]))
            .withBody(.data(mutableRequest.httpBody))

        let signingName: String
        switch endpointType {
        case .graphQL:
            signingName = URLRequestConstants.appSyncServiceName
        case .rest:
            signingName = URLRequestConstants.apiGatewayServiceName

        }

        guard let urlRequest = try await AmplifyAWSSignatureV4Signer().sigV4SignedRequest(requestBuilder: requestBuilder,
                                                                                    credentialsProvider: iamCredentialsProvider.getCredentialsProvider(),
                                                                                    signingName: signingName,
                                                                                    signingRegion: region,
                                                                                    date: Date()) else {
            throw APIError.unknown("Unable to sign request", "")
        }

        for header in urlRequest.headers.headers {
            mutableRequest.setValue(header.value.joined(separator: ","), forHTTPHeaderField: header.name)
        }

        return mutableRequest as URLRequest
    }
}
