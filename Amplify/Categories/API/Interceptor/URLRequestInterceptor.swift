//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A URLRequestInterceptor accepts a request and returns a request. It is invoked
/// during the "prepare" phase of an API operation.
///
/// A URLRequestInterceptor may use the request as a data source for some other
/// operation (e.g., metrics or logging), or use it as the source for preparing a
/// new request that will be used to fulfill the operation. For example, a
/// URLRequestInterceptor may add custom headers to the request for authorization.
///
/// URLRequestInterceptors are invoked in the order in which they are added to the
/// plugin.
public protocol URLRequestInterceptor {

    // swiftlint:disable:next todo
    // TODO: turn async https://github.com/aws-amplify/amplify-ios/issues/73
    /// Inspect and optionally modify the request, returning either the original
    /// unmodified request or a modified copy.
    /// - Parameter request: The URLRequest
    func intercept(_ request: URLRequest) throws -> URLRequest

    func intercept(_ request: URLRequest, completion: @escaping (Result<URLRequest, Error>) -> Void)
}

extension URLRequestInterceptor {

    public func intercept(_ request: URLRequest, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        do {
            let request = try intercept(request)
            completion(.success(request))
        } catch {
            completion(.failure(error))
        }

    }
}

