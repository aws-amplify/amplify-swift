//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import AWSS3
import ClientRuntime
import AWSClientRuntime

enum AWSS3PreSignedURLBuilderError: Error {
    case failed(reason: String, error: Error?)
}

// Behavior that the implemenation class for AWSS3PreSignedURLBuilder will use.
protocol AWSS3PreSignedURLBuilderBehavior {

    /// Gets a pre-signed URL.
    /// - Returns: Pre-Signed URL
    func getPreSignedURL(_ requestBuilder: SdkHttpRequestBuilder) throws -> URL

}

extension AWSS3PreSignedURLBuilderBehavior {
    func getPreSignedURL(_ urlRequest: URLRequest, body: Data? = nil) throws -> URL {
        let requestBuilder = try urlRequest.createSdkRequestBuilder(body: body)
        return try getPreSignedURL(requestBuilder)
    }

    func getPreSignedURL(_ requestURL: URL,
                         httpMethod: HttpMethodType = .get,
                         allHTTPHeaderFields: [String : String]? = nil,
                         body: Data? = nil) throws -> URL {
        let requestBuilder = try requestURL.createSdkRequestBuilder(httpMethod: httpMethod,
                                                                    allHTTPHeaderFields: allHTTPHeaderFields,
                                                                    body: body)
        return try getPreSignedURL(requestBuilder)
    }
}

extension URLRequest {

    func createSdkRequestBuilder(body: Data? = nil) throws -> SdkHttpRequestBuilder {
        guard let url = url,
              let host = url.host,
              let httpMethod = httpMethod,
              let httpMethod = HttpMethodType(rawValue: httpMethod.uppercased()) else {
                  throw AWSS3PreSignedURLBuilderError.failed(reason: "Insufficient values in URLRequest", error: nil)
              }

        let requestBuilder = SdkHttpRequestBuilder()
            .withHost(host)
            .withPath(url.path)
            .withMethod(httpMethod)
            .withPort(443)
            .withProtocol(.https)
            .withHeaders(.init(allHTTPHeaderFields ?? [:]))
            .withBody(.data(body))

        return requestBuilder
    }

}

extension URL {

    func createSdkRequestBuilder(httpMethod: HttpMethodType = .get,
                                 allHTTPHeaderFields: [String : String]? = nil,
                                 body: Data? = nil) throws -> SdkHttpRequestBuilder {
        guard let host = self.host else {
            throw AWSS3PreSignedURLBuilderError.failed(reason: "Missing host from URL", error: nil)
        }

        let requestBuilder = SdkHttpRequestBuilder()
            .withHost(host)
            .withPath(path)
            .withMethod(httpMethod)
            .withPort(443)
            .withProtocol(.https)
            .withHeaders(.init(allHTTPHeaderFields ?? [:]))
            .withBody(.data(body))

        return requestBuilder
    }

}
