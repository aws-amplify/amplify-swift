//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `AWSHTTPURLResponse` contains the response body and metadata associated with the response to an HTTP request.
///
/// When using `AWSAPIPlugin`, you can optionally type cast `HTTPURLResponse` to an instances of `AWSHTTPURLResponse`.
/// The response body can be accessed from the `body: Data?` property. For example, when the `APIError` is an
/// `.httpStatusError(StatusCode, HTTPURLResponse)`, then access the response body by type casting the response to
/// an `AWSHTTPURLResponse` and retrieve the `body` field.
/// ```swift
/// if case let .httpStatusError(statusCode, response) = error, let awsResponse = response as? AWSHTTPURLResponse {
///     if let responseBody = awsResponse.body {
///         print("Response contains a response body")
///     }
/// }
/// ```
/// **Note**: The class inheritance to `HTTPURLResponse` is to provide above mechanism, and actual
/// implementation acts as a facade that stores an instance of `HTTPURLResponse` that delegates overidden methods to
/// this stored property.
public class AWSHTTPURLResponse: HTTPURLResponse {

    /// The response body of the response
    public let body: Data?

    private let response: HTTPURLResponse

    init?(response: HTTPURLResponse, body: Data?) {
        self.body = body
        self.response = response

        // Call the super class initializer with dummy values to satisfy the requirement of the inheritance.
        super.init(url: URL(string: "dummyURL")!,
                   statusCode: 0,
                   httpVersion: nil,
                   headerFields: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented and is not expected to be called.")
    }

    public override var url: URL? {
        response.url
    }

    public override var mimeType: String? {
        response.mimeType
    }

    public override var expectedContentLength: Int64 {
        response.expectedContentLength
    }

    public override var textEncodingName: String? {
        response.textEncodingName
    }

    public override var suggestedFilename: String? {
        response.suggestedFilename
    }

    public override var statusCode: Int {
        response.statusCode
    }

    public override var allHeaderFields: [AnyHashable: Any] {
        response.allHeaderFields
    }

    @available(iOS 13.0, *)
    public override func value(forHTTPHeaderField field: String) -> String? {
        response.value(forHTTPHeaderField: field)
    }
}
