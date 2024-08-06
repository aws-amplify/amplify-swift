//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSClientRuntime // AWSClientRuntime.CredentialsProviding
import ClientRuntime // SdkHttpRequestBuilder
import InternalAmplifyCredentials // AmplifyAWSCredentialsProvider()
import AwsCommonRuntimeKit // CommonRuntimeKit.initialize()

extension AWSCognitoAuthPlugin {

    public static func createAppSyncSigner(region: String) -> ((URLRequest) async throws -> URLRequest) {
        return { request in
            try await signAppSyncRequest(request, region: region)
        }
    }
    public static func signAppSyncRequest(_ urlRequest: URLRequest,
                                          region: Swift.String,
                                          credentialsProvider: AWSClientRuntime.CredentialsProviding = AmplifyAWSCredentialsProvider(),
                                          signingName: Swift.String = "appsync",
                                          date: ClientRuntime.Date = Date()) async throws -> URLRequest {
        CommonRuntimeKit.initialize()

        // Convert URLRequest to SDK's HTTPRequest
        guard let requestBuilder = try createAppSyncSdkHttpRequestBuilder(
            urlRequest: urlRequest) else {
            return urlRequest
        }

        // Retrieve the credentials from credentials provider
        let credentials = try await credentialsProvider.getCredentials()

        // Prepare signing
        let flags = SigningFlags(useDoubleURIEncode: true,
                                 shouldNormalizeURIPath: true,
                                 omitSessionToken: false)
        let signedBodyHeader: AWSSignedBodyHeader = .none
        let signedBodyValue: AWSSignedBodyValue = .empty
        let signingConfig = AWSSigningConfig(credentials: credentials,
                                             signedBodyHeader: signedBodyHeader,
                                             signedBodyValue: signedBodyValue,
                                             flags: flags,
                                             date: date,
                                             service: signingName,
                                             region: region,
                                             signatureType: .requestHeaders,
                                             signingAlgorithm: .sigv4)

        // Sign request
        guard let httpRequest = await AWSSigV4Signer.sigV4SignedRequest(
            requestBuilder: requestBuilder,

            signingConfig: signingConfig
        ) else {
            return urlRequest
        }

        // Update original request with new headers
        return setHeaders(from: httpRequest, to: urlRequest)
    }

    static func setHeaders(from sdkRequest: SdkHttpRequest, to urlRequest: URLRequest) -> URLRequest {
        var urlRequest = urlRequest
        for header in sdkRequest.headers.headers {
            urlRequest.setValue(header.value.joined(separator: ","), forHTTPHeaderField: header.name)
        }
        return urlRequest
    }

    static func createAppSyncSdkHttpRequestBuilder(urlRequest: URLRequest) throws -> SdkHttpRequestBuilder? {

        guard let url = urlRequest.url,
              let host = url.host else {
            return nil
        }

        var headers = urlRequest.allHTTPHeaderFields ?? [:]
        headers.updateValue(host, forKey: "host")

        let httpMethod = (urlRequest.httpMethod?.uppercased())
            .flatMap(HttpMethodType.init(rawValue:)) ?? .get

        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?
            .map { ClientRuntime.SDKURLQueryItem(name: $0.name, value: $0.value)} ?? []

        let requestBuilder = SdkHttpRequestBuilder()
            .withHost(host)
            .withPath(url.path)
            .withQueryItems(queryItems)
            .withMethod(httpMethod)
            .withPort(443)
            .withProtocol(.https)
            .withHeaders(.init(headers))
            .withBody(.data(urlRequest.httpBody))

        return requestBuilder
    }
}
